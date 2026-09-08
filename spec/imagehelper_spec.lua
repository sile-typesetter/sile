-- Unit tests of the original libtexpdf based image bounding box detection,
-- the Lua based laternative for other outputters, a proposed C module
-- replacement, and soon to be an alternative proposed Rust replacement.

SILE = require("core.sile")
local rusile = require("rusile")

local imagehelper = require("imagehelper")
local pdf = require("justenoughlibtexpdf")

local callable = require("luassert.util").callable

local a_png = "documentation/gutenberg.png"
local png_llx, png_lly, png_urx, png_ury, png_xresol, png_yresol =
   0, 0, 144.00028800057603462, 174.96034992069988334, 99.99979999999997915, 99.99979999999997915

-- ImageMagick conversion to JPEG rounds the DPI to an integer
local a_jpg = "documentation/gutenberg.jpg"
local jpg_llx, jpg_lly, jpg_urx, jpg_ury, jpg_xresol, jpg_yresol =
   png_llx, png_lly, 144.0000, 174.9600, 100.0000, 100.0000

-- ImageMagick conversion to JPEG 2000 doesn't have any DPI value at all
local a_jp2 = "documentation/gutenberg.jp2"
local jp2_llx, jp2_lly, jp2_urx, jp2_ury, jp2_xresol, jp2_yresol = png_llx, png_lly, 200.0000, 243.000, 72.0000, 72.0000

local a_pdf = "documentation/sile-logo.pdf"
local pdf_llx, pdf_lly, pdf_urx, pdf_ury = 0, 0, 288.0290, 162.1890

local round = SILE.utilities.debug_round

pdf.init("/dev/null", 500, 500, "producer")

describe("pdf.imagebbox", function ()
   local imagebbox = pdf.imagebbox

   it("exists", function ()
      assert.is.truthy(callable(imagebbox))
   end)

   it("measures PNGs", function ()
      local llx, lly, urx, ury, xresol, yresol = imagebbox(a_png, 1)
      assert.is.equal(round(png_llx), round(llx))
      assert.is.equal(round(png_lly), round(lly))
      assert.is.equal(round(png_urx), round(urx))
      assert.is.equal(round(png_ury), round(ury))
      assert.is.equal(round(png_xresol), round(xresol))
      assert.is.equal(round(png_yresol), round(yresol))
   end)

   it("measures JPGs", function ()
      local llx, lly, urx, ury, xresol, yresol = imagebbox(a_jpg, 1)
      assert.is.equal(round(jpg_llx), round(llx))
      assert.is.equal(round(jpg_lly), round(lly))
      assert.is.equal(round(jpg_urx), round(urx))
      assert.is.equal(round(jpg_ury), round(ury))
      assert.is.equal(round(jpg_xresol), round(xresol))
      assert.is.equal(round(jpg_yresol), round(yresol))
   end)

   it("measures JP2s", function ()
      local llx, lly, urx, ury, xresol, yresol = imagebbox(a_jp2, 1)
      assert.is.equal(round(jp2_llx), round(llx))
      assert.is.equal(round(jp2_lly), round(lly))
      assert.is.equal(round(jp2_urx), round(urx))
      assert.is.equal(round(jp2_ury), round(ury))
      assert.is.equal(round(jp2_xresol), round(xresol))
      assert.is.equal(round(jp2_yresol), round(yresol))
   end)

   it("measures PDFs", function ()
      local llx, lly, urx, ury = imagebbox(a_pdf, 1)
      assert.is.equal(round(pdf_llx), round(llx))
      assert.is.equal(round(pdf_lly), round(lly))
      assert.is.equal(round(pdf_urx), round(urx))
      assert.is.equal(round(pdf_ury), round(ury))
   end)
end)

describe("imagehelper.bbox", function ()
   local bbox = imagehelper.bbox

   it("exists", function ()
      assert.is.truthy(callable(bbox))
   end)

   it("measures PNGs", function ()
      local llx, lly, urx, ury, xresol, yresol = bbox(a_png, 1)
      assert.is.equal(round(png_llx), round(llx))
      assert.is.equal(round(png_lly), round(lly))
      assert.is.equal(round(png_urx), round(urx))
      assert.is.equal(round(png_ury), round(ury))
      assert.is.equal(round(png_xresol), round(xresol))
      assert.is.equal(round(png_yresol), round(yresol))
   end)

   it("measures JPGs", function ()
      local llx, lly, urx, ury, xresol, yresol = bbox(a_jpg, 1)
      assert.is.equal(round(jpg_llx), round(llx))
      assert.is.equal(round(jpg_lly), round(lly))
      assert.is.equal(round(jpg_urx), round(urx))
      assert.is.equal(round(jpg_ury), round(ury))
      assert.is.equal(round(jpg_xresol), round(xresol))
      assert.is.equal(round(jpg_yresol), round(yresol))
   end)

   it("measures JP2s", function ()
      local llx, lly, urx, ury, xresol, yresol = bbox(a_jp2, 1)
      assert.is.equal(round(jp2_llx), round(llx))
      assert.is.equal(round(jp2_lly), round(lly))
      assert.is.equal(round(jp2_urx), round(urx))
      assert.is.equal(round(jp2_ury), round(ury))
      assert.is.equal(round(jp2_xresol), round(xresol))
      assert.is.equal(round(jp2_yresol), round(yresol))
   end)

   it("measures PDFs", function ()
      local llx, lly, urx, ury = bbox(a_pdf, 1)
      assert.is.equal(round(pdf_llx), round(llx))
      assert.is.equal(round(pdf_lly), round(lly))
      assert.is.equal(round(pdf_urx), round(urx))
      assert.is.equal(round(pdf_ury), round(ury))
   end)
end)

describe("rusile.imagebbox", function ()
   local imagebbox = rusile.imagebbox

   it("should exist", function ()
      assert.is.truthy(callable(imagebbox))
   end)

   it("measures PNGs", function ()
      local llx, lly, urx, ury, xresol, yresol = imagebbox(a_png, 1)
      assert.is.equal(round(png_llx), round(llx:tonumber()))
      assert.is.equal(round(png_lly), round(lly:tonumber()))
      assert.is.equal(round(png_urx), round(urx:tonumber()))
      assert.is.equal(round(png_ury), round(ury:tonumber()))
      assert.is.equal(round(png_xresol), round(xresol))
      assert.is.equal(round(png_yresol), round(yresol))
   end)

   it("measures JPGs", function ()
      local llx, lly, urx, ury, xresol, yresol = imagebbox(a_jpg, 1)
      assert.is.equal(round(jpg_llx), round(llx:tonumber()))
      assert.is.equal(round(jpg_lly), round(lly:tonumber()))
      assert.is.equal(round(jpg_urx), round(urx:tonumber()))
      assert.is.equal(round(jpg_ury), round(ury:tonumber()))
      assert.is.equal(round(jpg_xresol), round(xresol))
      assert.is.equal(round(jpg_yresol), round(yresol))
   end)

   it("measures JP2s", function ()
      local llx, lly, urx, ury, xresol, yresol = imagebbox(a_jp2, 1)
      assert.is.equal(round(jp2_llx), round(llx:tonumber()))
      assert.is.equal(round(jp2_lly), round(lly:tonumber()))
      assert.is.equal(round(jp2_urx), round(urx:tonumber()))
      assert.is.equal(round(jp2_ury), round(ury:tonumber()))
      assert.is.equal(round(jp2_xresol), round(xresol))
      assert.is.equal(round(jp2_yresol), round(yresol))
   end)

   it("measures PDFs", function ()
      local llx, lly, urx, ury = imagebbox(a_pdf, 1)
      assert.is.equal(round(pdf_llx), round(llx:tonumber()))
      assert.is.equal(round(pdf_lly), round(lly:tonumber()))
      assert.is.equal(round(pdf_urx), round(urx:tonumber()))
      assert.is.equal(round(pdf_ury), round(ury:tonumber()))
   end)

   it("defaults the page to 1", function ()
      local _, _, urx, ury = imagebbox(a_pdf)
      assert.is.equal(round(pdf_urx), round(urx:tonumber()))
      assert.is.equal(round(pdf_ury), round(ury:tonumber()))
   end)

   it("returns nil resolution for PDFs", function ()
      local _, _, _, _, xresol, yresol = imagebbox(a_pdf)
      assert.is_nil(xresol)
      assert.is_nil(yresol)
   end)

   it("errors on a missing file", function ()
      assert.has_error(function ()
         imagebbox("does-not-exist.png")
      end)
   end)
end)

describe("rusile.imagenumpages", function ()
   local imagenumpages = rusile.imagenumpages

   it("should exist", function ()
      assert.is.truthy(callable(imagenumpages))
   end)

   it("counts PDF pages", function ()
      assert.is.equal(imagenumpages(a_pdf), 1)
   end)

   it("reports 1 for raster images", function ()
      assert.is.equal(imagenumpages(a_png), 1)
   end)
end)
