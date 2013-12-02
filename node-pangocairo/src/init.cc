#include "PangoCairo.h"
#include "Cairo.h"
#include "Pango.h"
#include "PangoAttrList.h"

extern "C" void
init (Handle<Object> target) {
  HandleScope scope;
  Cairo::Initialize(target);
  Pango::Initialize(target);
  NodePangoAttrList::Initialize(target);
  target->Set(String::New("cairoVersion"), String::New(cairo_version_string()));
  target->Set(String::New("pangoVersion"), String::New(pango_version_string()));
}

NODE_MODULE(pangocairo,init);
