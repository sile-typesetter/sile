-- Unit tests of the original libtexpdf based image bounding box detection,
-- the Lua based laternative for other outputters, a proposed C module
-- replacement, and soon to be an alternative proposed Rust replacement.

SILE = require("core.sile")

local imagehelper = require("imagehelper")
local pdf = require("justenoughlibtexpdf")

local callable = require("luassert.util").callable

local a_png = "documentation/gutenberg.png"
local png_llx, png_lly, png_urx, png_ury, png_xresol, png_yresol =
   0, 0, 144.00028800057603462, 174.96034992069988334, 99.99979999999997915, 99.99979999999997915

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

   it("measures PDFs", function ()
      local llx, lly, urx, ury = bbox(a_pdf, 1)
      assert.is.equal(round(pdf_llx), round(llx))
      assert.is.equal(round(pdf_lly), round(lly))
      assert.is.equal(round(pdf_urx), round(urx))
      assert.is.equal(round(pdf_ury), round(ury))
   end)
end)
