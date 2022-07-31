#include <stdlib.h>
#include <stdio.h>
#include "libtexpdf/libtexpdf.h"

int get_pdf_bbox(FILE* f, double* llx, double* lly, double* urx, double* ury) {
  pdf_obj* page;
  long page_no = 1;
  long count;
  pdf_rect bbox;
  pdf_file* pf = texpdf_open(NULL, f);
  if (!pf) {
    return -1;
  }

  page = texpdf_doc_get_page(pf, page_no, &count, &bbox, NULL);

  texpdf_close(pf);

  if (!page)
    return -1;

  texpdf_release_obj(page);

  *llx = bbox.llx;
  *lly = bbox.lly;
  *urx = bbox.urx;
  *ury = bbox.ury;
  return 0;
}

int get_image_bbox(FILE* f, double* llx, double* lly, double* urx, double* ury, double* xresol, double* yresol) {
  int width, height;
  uint32_t w2, h2;
  double xdensity, ydensity;

  if (texpdf_check_for_bmp(f)) {
    if(texpdf_bmp_get_bbox(f, &width, &height, &xdensity, &ydensity) < 0) {
      return -1;
    }
  } else if (texpdf_check_for_jpeg(f)) {
    if(texpdf_jpeg_get_bbox(f, &width, &height, &xdensity, &ydensity) < 0) {
      return -1;
    }
  } else if (texpdf_check_for_jp2(f)) {
    if(texpdf_jp2_get_bbox(f, &width, &height, &xdensity, &ydensity) < 0) {
      return -1;
    }
  } else if (texpdf_check_for_png(f)) {
    if(texpdf_png_get_bbox(f, &w2, &h2, &xdensity, &ydensity) < 0) {
      return -1;
    }
    width = w2;
    height = h2;
  } else if (texpdf_check_for_pdf(f)) {
    *xresol = 0;
    *yresol = 0;
    return get_pdf_bbox(f, llx, lly, urx, ury);
  } else {
    return -1;
  }

  *llx = 0;
  *lly =0;
  // pixels -> pt
  *urx = width * xdensity;
  *ury = height * ydensity;
  // texpdf density is in pt/in
  *xresol = xdensity != 0 ? 72 / xdensity : 0;
  *yresol = ydensity != 0 ? 72 / ydensity : 0;
  return 0;
}


