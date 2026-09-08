//! This module has image metadata helpers designed as drop in replacements for libtexpdf provided
//! functions. Providing them ourselves allows us more flexibility for updating libtexpdf and also
//! consistency when using other backends that don't provide the same helpers. The results should be
//! bit for bit compatible with what libtexpdf would calculate, but support more image formats,
//! re-entry, etc.

use std::fs::File;
use std::io::Read;
use std::mem::swap;
use std::path::{Path, PathBuf};

use anyhow::{Context, anyhow};
use imageinfo::{ImageFormat, ImageInfo};
use lopdf::{Dictionary, Document, Object};

use crate::Result;
use crate::types::PageNo;
use crate::types::image::ImageBBox;
use crate::types::{PageNo, Points};

/// Determine the image extents (bounding box) and resolution for raster and some vector image assets.
///
/// `page` is 1-based and only meaningful for PDF documents.
pub fn imagebbox(path: PathBuf, page: PageNo) -> Result<ImageBBox> {
    if is_pdf(path.as_path())? {
        pdf_bbox(path.as_path(), page)
    } else {
        raster_bbox(path.as_path())
    }
}

/// Detect whether a file is a PDF by sniffing the `%PDF` magic bytes, rather
/// than trusting the file extension alone. Returns an error if the file cannot
/// be read.
fn is_pdf(path: &Path) -> Result<bool> {
    let mut file = File::open(path).with_context(|| format!("failed to open {path:?}"))?;
    let mut head = [0u8; 5];
    let n = file
        .read(&mut head)
        .with_context(|| format!("failed to read {path:?}"))?;
    Ok(n == 5 && &head == b"%PDF-")
}

fn raster_bbox(path: &Path) -> Result<ImageBBox> {
    let bytes = read_head(path, 1 << 20)?;
    let info = ImageInfo::from_raw_data(&bytes)
        .with_context(|| format!("failed to read image metadata for {path:?}"))?;
    let width = info.size.width as f64;
    let height = info.size.height as f64;
    let (xdpi, ydpi) = raster_density(&info, &bytes)?;
    Ok(ImageBBox {
        llx: 0.0,
        lly: 0.0,
        urx: width * 72.0 / xdpi,
        ury: height * 72.0 / ydpi,
        xdpi: Some(xdpi),
        ydpi: Some(ydpi),
    })
}

/// Determine the pixel density (DPI) of a raster image, defaulting to 72 DPI
/// when the file does not carry an unambiguous physical size.
fn raster_density(info: &ImageInfo, bytes: &[u8]) -> Result<(f64, f64)> {
    let default = (72.0, 72.0);
    Ok(match info.format {
        // JP2/J2K don't expose a cheap density here; WebP, BMP and the rest
        // default to 72 DPI, matching libtexpdf/imagehelper behavior.
        ImageFormat::PNG => png_dpi_from_bytes(bytes).unwrap_or(default),
        ImageFormat::JPEG => jpeg_dpi_from_bytes(bytes).unwrap_or(default),
        _ => default,
    })
}

/// Read the PNG `pHYs` chunk (pixels per meter) out of raw file bytes and
/// convert to DPI, if present with a physical unit. A `pHYs` with unit 0 only
/// describes aspect ratio, so it is ignored in favor of the 72 DPI default.
fn png_dpi_from_bytes(bytes: &[u8]) -> Option<(f64, f64)> {
    let mut offset = 8; // skip the 8-byte PNG signature
    while offset + 8 <= bytes.len() {
        let length = u32::from_be_bytes(bytes[offset..offset + 4].try_into().ok()?) as usize;
        let kind = &bytes[offset + 4..offset + 8];
        if kind == b"pHYs" && offset + 8 + 9 <= bytes.len() {
            let xppm = u32::from_be_bytes(bytes[offset + 8..offset + 12].try_into().ok()?);
            let yppm = u32::from_be_bytes(bytes[offset + 12..offset + 16].try_into().ok()?);
            let unit = bytes[offset + 16];
            if unit == 1 {
                // unit 1 == pixels per meter.
                return Some((xppm as f64 * 0.0254, yppm as f64 * 0.0254));
            }
            return None;
        }
        // Chunk: 4-byte length + 4-byte type + data + 4-byte CRC.
        offset += 12 + length;
        if kind == b"IEND" {
            break;
        }
    }
    None
}

/// Read the JPEG JFIF APP0 density out of raw file bytes. Units 1 and 2 are DPI
/// and pixels per centimeter respectively; unit 0 (aspect ratio only) is ignored.
fn jpeg_dpi_from_bytes(bytes: &[u8]) -> Option<(f64, f64)> {
    // Scan JPEG markers looking for the APP0 segment carrying the "JFIF" marker.
    let mut offset = 2; // skip SOI (0xFFD8)
    while offset + 4 <= bytes.len() {
        if bytes[offset] != 0xFF {
            break;
        }
        let marker = bytes[offset + 1];
        // Skip fill bytes.
        if marker == 0xFF {
            offset += 1;
            continue;
        }
        // Standalone markers carry no length.
        if matches!(marker, 0x01 | 0xD8 | 0xD9) {
            offset += 2;
            continue;
        }
        if offset + 4 > bytes.len() {
            break;
        }
        let seg_len = u16::from_be_bytes(bytes[offset + 2..offset + 4].try_into().ok()?) as usize;
        let payload = offset + 4;
        if marker == 0xE0 && payload + 5 <= bytes.len() && &bytes[payload..payload + 5] == b"JFIF\0"
        {
            if payload + 12 <= bytes.len() {
                let unit = bytes[payload + 7];
                let xdensity =
                    u16::from_be_bytes(bytes[payload + 8..payload + 10].try_into().ok()?);
                let ydensity =
                    u16::from_be_bytes(bytes[payload + 10..payload + 12].try_into().ok()?);
                let (xdpi, ydpi) = match unit {
                    1 => (xdensity as f64, ydensity as f64),
                    2 => (xdensity as f64 * 2.54, ydensity as f64 * 2.54),
                    _ => return None,
                };
                if xdpi > 0.0 && ydpi > 0.0 {
                    return Some((xdpi, ydpi));
                }
            }
            return None;
        }
        offset = payload + seg_len - 2;
    }
    None
}

/// Read up to `limit` bytes from the head of a file.
fn read_head(path: &Path, limit: usize) -> Result<Vec<u8>> {
    let mut file = File::open(path).with_context(|| format!("failed to open {path:?}"))?;
    let mut buf = Vec::with_capacity(limit);
    file.by_ref()
        .take(limit as u64)
        .read_to_end(&mut buf)
        .with_context(|| format!("failed to read {path:?}"))?;
    Ok(buf)
}

fn pdf_bbox(path: &Path, page: PageNo) -> Result<ImageBBox> {
    let doc = Document::load(path).with_context(|| format!("failed to open PDF {path:?}"))?;
    if doc.is_encrypted() {
        return Err(anyhow!("encrypted PDFs are not supported: {path:?}"));
    }
    let pages = doc.get_pages();
    let object_id = pages
        .get(&page.get())
        .copied()
        .ok_or_else(|| anyhow!("page {page} out of range in {path:?}"))?;
    let page_dict = doc
        .get_dictionary(object_id)
        .with_context(|| format!("invalid page object in {path:?}"))?;

    // Resolve the media box, falling back to the crop box, honoring PDF
    // inheritance through the /Pages tree.
    let media = fetch_box(&doc, page_dict, b"MediaBox");
    let rect = match media {
        Some(rect) => rect,
        None => fetch_box(&doc, page_dict, b"CropBox")
            .ok_or_else(|| anyhow!("page has neither MediaBox nor CropBox: {path:?}"))?,
    };

    let (mut llx, mut lly, mut urx, mut ury) = rect_to_coords(&doc, &rect)?;
    if (urx - llx) < 0.0 {
        swap(&mut llx, &mut urx);
    }
    if (ury - lly) < 0.0 {
        swap(&mut lly, &mut ury);
    }

    // Rotate handling: for 90/270-degree rotations the visual page size is the
    // box dimensions transposed, the way PDF viewers (and libtexpdf) report it.
    let rotate = fetch_inherited_int(&doc, page_dict, b"Rotate").unwrap_or(0) % 360;
    if rotate == 90 || rotate == 270 {
        let width = urx - llx;
        let height = ury - lly;
        urx = llx + height;
        ury = lly + width;
    }

    Ok(ImageBBox {
        llx,
        lly,
        urx,
        ury,
        xdpi: None,
        ydpi: None,
    })
}

/// Extract a rectangle (array of four numbers) from a dictionary, following
/// references and, when absent on a page, inherited from the parent `/Pages`
/// node.
fn fetch_box(doc: &Document, dict: &Dictionary, key: &[u8]) -> Option<Object> {
    if let Ok(obj) = dict.get_deref(key, doc) {
        match obj {
            Object::Array(_) => return Some(obj.clone()),
            Object::Reference(_) => unreachable!("get_deref dereferences references"),
            _ => {}
        }
    }
    // Walk up the parent chain searching for an inherited value.
    let mut current = dict.clone();
    while let Ok(parent_ref) = current.get(b"Parent").and_then(Object::as_reference) {
        let parent = doc.get_dictionary(parent_ref).ok()?;
        if let Ok(obj) = parent.get_deref(key, doc)
            && matches!(obj, Object::Array(_))
        {
            return Some(obj.clone());
        }
        current = parent.clone();
    }
    None
}

fn fetch_inherited_int(doc: &Document, dict: &Dictionary, key: &[u8]) -> Option<i64> {
    if let Ok(obj) = dict.get_deref(key, doc)
        && let Ok(v) = obj.as_i64()
    {
        return Some(v);
    }
    let mut current = dict.clone();
    while let Ok(parent_ref) = current.get(b"Parent").and_then(Object::as_reference) {
        let parent = doc.get_dictionary(parent_ref).ok()?;
        if let Ok(obj) = parent.get_deref(key, doc)
            && let Ok(v) = obj.as_i64()
        {
            return Some(v);
        }
        current = parent.clone();
    }
    None
}

/// Convert a rectangle object (array of four numbers, any numeric type) to
/// `(llx, lly, urx, ury)` coordinates.
fn rect_to_coords(doc: &Document, rect: &Object) -> Result<(f64, f64, f64, f64)> {
    let arr = rect.as_array().context("box is not an array")?;
    if arr.len() != 4 {
        return Err(anyhow!("box must contain exactly 4 numbers"));
    }
    let get = |o: &Object| -> Result<f64> {
        let o = match o {
            // Rectangles are rarely indirect, but handle it for robustness.
            Object::Reference(id) => doc.get_object(*id)?,
            _ => o,
        };
        o.as_float()
            .map(|v| v as f64)
            .map_err(|_| anyhow!("box element is not numeric"))
    };
    Ok((get(&arr[0])?, get(&arr[1])?, get(&arr[2])?, get(&arr[3])?))
}
