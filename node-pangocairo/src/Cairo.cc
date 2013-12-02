#include "PangoCairo.h"
#include "Cairo.h"

Persistent<FunctionTemplate> Cairo::constructor;

void
Cairo::Initialize(Handle<Object> target) {
  HandleScope scope;

  // Constructor
  constructor = Persistent<FunctionTemplate>::New(FunctionTemplate::New(Cairo::New));
  constructor->InstanceTemplate()->SetInternalFieldCount(1);
  constructor->SetClassName(String::NewSymbol("Cairo"));

  // Prototype
  //Local<ObjectTemplate> proto = constructor->PrototypeTemplate();
  NODE_SET_PROTOTYPE_METHOD(constructor, "save", Save);
  NODE_SET_PROTOTYPE_METHOD(constructor, "restore", Restore);
  NODE_SET_PROTOTYPE_METHOD(constructor, "setSourceRGB", SetSourceRGB);
  NODE_SET_PROTOTYPE_METHOD(constructor, "setSourceRGBA", SetSourceRGBA);
  NODE_SET_PROTOTYPE_METHOD(constructor, "moveTo", MoveTo);
  NODE_SET_PROTOTYPE_METHOD(constructor, "selectFontFace", SelectFontFace);
  NODE_SET_PROTOTYPE_METHOD(constructor, "setFontSize", SetFontSize);
  NODE_SET_PROTOTYPE_METHOD(constructor, "showText", ShowText);
  NODE_SET_PROTOTYPE_METHOD(constructor, "showGlyphString", ShowGlyphString);
  NODE_SET_PROTOTYPE_METHOD(constructor, "showAGlyph", ShowAGlyph);
  NODE_SET_PROTOTYPE_METHOD(constructor, "rectangle", Rectangle);

  NODE_SET_PROTOTYPE_METHOD(constructor, "showPage", ShowPage);
  NODE_SET_PROTOTYPE_METHOD(constructor, "finish", Finish);
  
  target->Set(String::NewSymbol("Cairo"), constructor->GetFunction());
}


Handle<Value>
Cairo::New(const Arguments &args) {
  HandleScope scope;
  int width = 0, height = 0;
  char* filename = NULL;
  canvas_type_t type = CANVAS_TYPE_IMAGE;
  if (args[0]->IsNumber()) width = args[0]->Uint32Value();
  if (args[1]->IsNumber()) height = args[1]->Uint32Value();
  if (args[2]->IsString()) type = !strcmp("pdf", *String::AsciiValue(args[2]))
    ? CANVAS_TYPE_PDF
    : CANVAS_TYPE_IMAGE;
  if (args[3]->IsString()) filename = *String::AsciiValue(args[3]);
  Cairo *context = new Cairo(width, height, type, filename);
  context->Wrap(args.This());
  return args.This();
}

Cairo::Cairo(int w, int h, canvas_type_t t, char* filename): ObjectWrap() {
  width = w;
  _surface = NULL;

  if (CANVAS_TYPE_PDF == t) {
    _surface = cairo_pdf_surface_create(filename, w, h);
  } else {
    _surface = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, w, h);
    assert(_surface);
    V8::AdjustAmountOfExternalAllocatedMemory(4 * w * h);
  }
  _cairo = cairo_create(_surface);
}

Handle<Value>
Cairo::Save(const Arguments &args) {
  HandleScope scope;
  Cairo *cc = ObjectWrap::Unwrap<Cairo>(args.This());
  cairo_save(cc->_cairo);
  return Undefined();
}

Handle<Value>
Cairo::Restore(const Arguments &args) {
  HandleScope scope;
  Cairo *cc = ObjectWrap::Unwrap<Cairo>(args.This());
  cairo_restore(cc->_cairo);
  return Undefined();
}

Handle<Value>
Cairo::SetSourceRGB(const Arguments &args) {
  HandleScope scope;
  Cairo *cc = ObjectWrap::Unwrap<Cairo>(args.This());
  cairo_set_source_rgb(cc->_cairo, args[0]->NumberValue(),
      args[1]->NumberValue(),args[2]->NumberValue());
  return Undefined();
} 

Handle<Value>
Cairo::SetSourceRGBA(const Arguments &args) {
  HandleScope scope;
  Cairo *cc = ObjectWrap::Unwrap<Cairo>(args.This());
  cairo_set_source_rgba(cc->_cairo, args[0]->NumberValue(),
      args[1]->NumberValue(),args[2]->NumberValue(), args[3]->NumberValue());
  return Undefined();
} 

Handle<Value>
Cairo::MoveTo(const Arguments &args) {
  HandleScope scope;
  Cairo *cc = ObjectWrap::Unwrap<Cairo>(args.This());
  cairo_move_to(cc->_cairo, args[0]->NumberValue(), args[1]->NumberValue());
  return Undefined();
} 


Handle<Value>
Cairo::Rectangle(const Arguments &args) {
  HandleScope scope;
  Cairo *cc = ObjectWrap::Unwrap<Cairo>(args.This());
  cairo_set_line_width(cc->_cairo, 0.5);
  cairo_rectangle(cc->_cairo, args[0]->NumberValue(), args[1]->NumberValue(),args[2]->NumberValue(), args[3]->NumberValue());
  cairo_stroke(cc->_cairo);
  return Undefined();
} 

Handle<Value>
Cairo::SelectFontFace(const Arguments &args) {
  HandleScope scope;
  String::Utf8Value f (args[0]->ToString());
  Cairo *cc = ObjectWrap::Unwrap<Cairo>(args.This());
  cairo_select_font_face(cc->_cairo, *f, CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_BOLD); // XXX
//      args[1]->IntegerValue(),args[2]->IntegerValue());
  return Undefined();
} 

Handle<Value>
Cairo::SetFontSize(const Arguments &args) {
  HandleScope scope;
  Cairo *cc = ObjectWrap::Unwrap<Cairo>(args.This());
  cairo_set_font_size(cc->_cairo, args[0]->NumberValue());
  return Undefined();
} 

Handle<Value>
Cairo::ShowText(const Arguments &args) {
  HandleScope scope;
  String::Utf8Value t (args[0]->ToString());
  Cairo *cc = ObjectWrap::Unwrap<Cairo>(args.This());
  cairo_show_text(cc->_cairo, *t);
  return Undefined();
} 

Handle<Value>
Cairo::ShowGlyphString(const Arguments &args) {
  HandleScope scope;
  Cairo *cc = ObjectWrap::Unwrap<Cairo>(args.This());

  PangoFont *pf = (PangoFont*)External::Unwrap(args[0]);
  PangoGlyphString *g = (PangoGlyphString*)External::Unwrap(args[1]);
  
  pango_cairo_show_glyph_string(cc->_cairo, pf, g);
  return Undefined();
} 

Handle<Value>
Cairo::ShowAGlyph(const Arguments &args) {
  HandleScope scope;
  Cairo *cc = ObjectWrap::Unwrap<Cairo>(args.This());
  gint *lg = { 0 };
  PangoFont *pf = (PangoFont*)External::Unwrap(args[0]);
  PangoGlyphInfo *g = (PangoGlyphInfo*)External::Unwrap(args[1]);
  PangoGlyphString gs = {1,g,lg};
  
  pango_cairo_show_glyph_string(cc->_cairo, pf, &gs);
  return v8::Boolean::New(true);
} 

Handle<Value>
Cairo::ShowPage(const Arguments &args) {
  HandleScope scope;
  Cairo *cc = ObjectWrap::Unwrap<Cairo>(args.This());
  cairo_show_page(cc->_cairo);
  return v8::Boolean::New(true);
}

Handle<Value>
Cairo::Finish(const Arguments &args) {
  HandleScope scope;
  Cairo *cc = ObjectWrap::Unwrap<Cairo>(args.This());

  if (cc->_surface) {
    cairo_surface_destroy(cc->_surface);
    cc->_surface = NULL;
  }
  if (cc->_cairo) {
    cairo_destroy(cc->_cairo);
    cc->_cairo = NULL;
  }
  return v8::Boolean::New(true);
}

Cairo::~Cairo() {
  if (_surface) {
    cairo_surface_destroy(_surface);
    _surface = NULL;
  }
  if (_cairo) {
    cairo_destroy(_cairo);
    _cairo = NULL;
  }
}
