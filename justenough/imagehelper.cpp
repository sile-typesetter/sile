// Lua bindings for a minimal image library "imagehelper".
//
// Supported formats:
//
//  - PDF (via poppler-cpp)
//  - PNG (via libpng)
//  - JPEG (via libjpeg)
//  - JPEG 2000 (via openjpeg)
//
// Features:
//  - Bounding box and resolution in DPI
//    Bounding box is returned in points (1/72 inch)
//    Resolution is return as nil for PDF and defaulted to 72 DPI for raster images if not available
//  - number of pages
//    For PDF, this is the actual number of pages.
//    For other formats, this is always 1.
//
// License: MIT
// (c) 2026 Didier Willis / Omikhleia / The SILE Typesetter

#include <lua.h>
#include <lauxlib.h>

// PNG LOGIC

#include <png.h>

static void custom_png_error(png_structp png_ptr, png_const_charp error_msg) {
    // Silence error messages from libpng
    // and return control to the caller for setjmp to handle.
    longjmp(png_jmpbuf(png_ptr), 1);
}

static void custom_png_warning(png_structp png_ptr, png_const_charp warning_msg) {
    // No-op:
    // Silence warning messages from libpng.
}

static int bbox_png(lua_State* L, const char* path) {
    FILE* f = fopen(path, "rb");
    if (!f) {
        return -1;
    }

    png_structp png = png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, custom_png_error, custom_png_warning);
    if (!png) {
        fclose(f);
        return -1;
    }
    png_infop info = png_create_info_struct(png);
    if (!png || !info || setjmp(png_jmpbuf(png))) {
        png_destroy_read_struct(&png, &info, NULL);
        fclose(f);
        return -1;
    }

    png_init_io(png, f);
    png_read_info(png, info);

    png_uint_32 w, h;
    png_get_IHDR(png, info, &w, &h, NULL, NULL, NULL, NULL, NULL);

    double xdpi = 72.0;
    double ydpi = 72.0;

    png_uint_32 xppm, yppm;
    int unit;

    if (png_get_pHYs(png, info, &xppm, &yppm, &unit) &&
        unit == PNG_RESOLUTION_METER) {
        // If the physical pixel dimensions are specified in the file,
        // the only other supported unit is PNG_RESOLUTION_UNKNOWN,
        // which we cannot make much sense of.
        xdpi = xppm * 0.0254;
        ydpi = yppm * 0.0254;
    }

    png_destroy_read_struct(&png, &info, NULL);
    fclose(f);

    lua_pushnumber(L, 0);
    lua_pushnumber(L, 0);
    lua_pushnumber(L, w * 72.0 / xdpi);
    lua_pushnumber(L, h * 72.0 / ydpi);
    lua_pushnumber(L, xdpi);
    lua_pushnumber(L, ydpi);
    return 6;
}

// JPEG LOGIC

#include <jpeglib.h>

struct custom_jpeg_error_manager {
    jpeg_error_mgr pub;
    jmp_buf setjmp_buffer;
};

void custom_jpeg_error (j_common_ptr cinfo)
{
    // Silence error messages from libjpeg
    // and return control to the caller for setjmp to handle.
    custom_jpeg_error_manager* myerr = (custom_jpeg_error_manager*) cinfo->err;
    longjmp(myerr->setjmp_buffer, 1);
}

static int bbox_jpeg(lua_State* L, const char* path) {
    FILE* f = fopen(path, "rb");
    if (!f) {
        return -1;
    }

    jpeg_decompress_struct cinfo;
    custom_jpeg_error_manager cerr;
    cinfo.err = jpeg_std_error(&cerr.pub);
    cerr.pub.error_exit = custom_jpeg_error;
    if (setjmp(cerr.setjmp_buffer)) {
        jpeg_destroy_decompress(&cinfo);
        fclose(f);
        return -1;
    }

    jpeg_create_decompress(&cinfo);
    jpeg_stdio_src(&cinfo, f);
    if (jpeg_read_header(&cinfo, TRUE) != JPEG_HEADER_OK) {
        jpeg_destroy_decompress(&cinfo);
        fclose(f);
        return -1;
    }

    int w = cinfo.image_width;
    int h = cinfo.image_height;

    double xdpi = 72.0;
    double ydpi = 72.0;

    if (cinfo.density_unit == 1) { // dots per inch
        xdpi = cinfo.X_density;
        ydpi = cinfo.Y_density;
    } else if (cinfo.density_unit == 2) { // dots per cm
        xdpi = cinfo.X_density * 2.54;
        ydpi = cinfo.Y_density * 2.54;
    }

    if (xdpi <= 0.0) xdpi = 72.0;
    if (ydpi <= 0.0) ydpi = 72.0;

    jpeg_destroy_decompress(&cinfo);
    fclose(f);

    double W = w * 72.0 / xdpi;
    double H = h * 72.0 / ydpi;

    lua_pushnumber(L, 0);
    lua_pushnumber(L, 0);
    lua_pushnumber(L, W);
    lua_pushnumber(L, H);
    lua_pushnumber(L, xdpi);
    lua_pushnumber(L, ydpi);
    return 6;
}

// JPEG 2000 LOGIC

#include <openjpeg.h>

static int bbox_jp2(lua_State* L, const char* path) {
    opj_stream_t* stream = opj_stream_create_default_file_stream(path, 1);
    if (!stream) return 0;

    opj_codec_t* codec = opj_create_decompress(OPJ_CODEC_JP2);
    opj_setup_decoder(codec, NULL);

    opj_image_t* image = NULL;
    if (!opj_read_header(stream, codec, &image)) {
        opj_destroy_codec(codec);
        opj_stream_destroy(stream);
        return 0;
    }

    // Assume the first component defines the dimensions
    // (Most JP2 files have all components the same size, but this is not guaranteed)
    int w = image->comps[0].w;
    int h = image->comps[0].h;

    // Resolution information might optionally be stored in JP2 boxes,
    // but openjpeg does not seem to provide an API to access it directly.
    // GIMP doesn't seem to set it either when exporting JP2 (when re-opening the file,
    // the resolution is always show as 72 DPI)
    // The JP2 implementation in SILE's libtexpdf doesn't do better.
    double xdpi = 72.0;
    double ydpi = 72.0;

    opj_image_destroy(image);
    opj_destroy_codec(codec);
    opj_stream_destroy(stream);

    double W = w * 72.0 / xdpi;
    double H = h * 72.0 / ydpi;

    lua_pushnumber(L, 0);
    lua_pushnumber(L, 0);
    lua_pushnumber(L, W);
    lua_pushnumber(L, H);
    lua_pushnumber(L, xdpi);
    lua_pushnumber(L, ydpi);
    return 6;
}

// PDF LOGIC

#include <poppler/cpp/poppler-document.h>
#include <poppler/cpp/poppler-page.h>

static void custom_poppler_error(const std::string&, void*) {
    // No-op:
    // Silence error messages from poppler.
}

static int bbox_pdf(lua_State* L, const char* path, int page) {
    poppler::set_debug_error_function(custom_poppler_error, nullptr);

    auto doc = poppler::document::load_from_file(path);
    if (!doc) {
        return -1;
    }

    auto p = doc->create_page(page - 1);
    if (!p) {
        // Page out of range
        return 0;
    }

    auto r = p->page_rect();

    lua_pushnumber(L, r.left());
    lua_pushnumber(L, r.top());
    lua_pushnumber(L, r.right());
    lua_pushnumber(L, r.bottom());
    lua_pushnil(L);
    lua_pushnil(L);
    return 6;
}

static int numpages_pdf(lua_State* L, const char* path) {
    poppler::set_debug_error_function(custom_poppler_error, nullptr);

    auto doc = poppler::document::load_from_file(path);
    if (!doc) {
        return -1;
    }

    lua_pushinteger(L, doc->pages());
    return 1;
}

// LUA BINDINGS

static int l_bbox(lua_State* L) {
    const char* path = luaL_checkstring(L, 1);
    int page = (int)luaL_optinteger(L, 2, 1);
    int res;

    // First try PDF
    res = bbox_pdf(L, path, page);
    if (res > 0) {
        return res;
    }
    if (res == 0) {
        return luaL_error(L, "Page %d out of range", page);
    }

    // Then PNG
    res = bbox_png(L, path);
    if (res > 0) {
        return res;
    }

    // Then JPEG
    res = bbox_jpeg(L, path);
    if (res > 0) {
        return res;
    }

    // Then JPEG 2000
    res = bbox_jp2(L, path);
    if (res > 0) {
        return res;
    }

    return luaL_error(L, "Unknown image type or failed to read file: %s", path);
}

static int l_numpages(lua_State* L) {
    const char* path = luaL_checkstring(L, 1);
    int res;

    // First try PDF
    res = numpages_pdf(L, path);
    if (res >= 0) {
        return res;
    }

    // Raster images are always considered to have a single "page"
    lua_pushinteger(L, 1);
    return 1;
}

// LUA REGISTRATION

static const luaL_Reg funcs[] = {
    { "bbox", l_bbox },
    { "numpages",  l_numpages },
    { NULL, NULL }
};

extern "C" int luaopen_imagehelper(lua_State *L) {
    lua_newtable(L);

    for (int i = 0; funcs[i].name != NULL; i++) {
        lua_pushcfunction(L, funcs[i].func);
        lua_setfield(L, -2, funcs[i].name);
    }

    return 1;
}
