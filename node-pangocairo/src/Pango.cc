#include "PangoCairo.h"
#include "Pango.h"
#include "PangoAttrList.h"
#include <stdlib.h>
#include <string.h>

Persistent<FunctionTemplate> Pango::constructor;

static const char* ToCString(const v8::String::Utf8Value& value) {
  return *value ? *value: "<string conversion failed>";
}

void
Pango::Initialize(Handle<Object> target) {
  HandleScope scope;

  // Constructor
  constructor = Persistent<FunctionTemplate>::New(FunctionTemplate::New(Pango::New));
  constructor->InstanceTemplate()->SetInternalFieldCount(1);
  constructor->SetClassName(String::NewSymbol("Pango"));

  // Prototype
  //Local<ObjectTemplate> proto = constructor->PrototypeTemplate();
  NODE_SET_PROTOTYPE_METHOD(constructor, "setLanguage", SetLanguage);
  NODE_SET_PROTOTYPE_METHOD(constructor, "itemizeAndShape", ItemizeAndShape);
  
  target->Set(String::NewSymbol("Pango"), constructor->GetFunction());
}


Handle<Value>
Pango::New(const Arguments &args) {
  HandleScope scope;
  Pango *p = new Pango();
  p->Wrap(args.This());
  return args.This();
}

Handle<Value>
Pango::SetLanguage(const Arguments &args) {
  HandleScope scope;
  v8::String::Utf8Value lang (args[0]->ToString());
  Pango *p = ObjectWrap::Unwrap<Pango>(args.This());

  pango_context_set_language(p->_pangocontext, pango_language_from_string(ToCString(lang)));
  return v8::Boolean::New(true);
}

Handle<Value>
Pango::ItemizeAndShape(const Arguments &args) {
  HandleScope scope;
  Pango *p = ObjectWrap::Unwrap<Pango>(args.This());
  int ii = 0;
  v8::String::Utf8Value s (args[0]->ToString());
  NodePangoAttrList *np = ObjectWrap::Unwrap<NodePangoAttrList>(args[1]->ToObject());

  GList* items = pango_itemize(p->_pangocontext, *s, 0, args[0]->ToString()->Utf8Length(), np->_attrlist, NULL);

  Handle<Array> arr = Array::New(0);

  while (items != NULL) {
    Handle<Object> o = Object::New();
    PangoRectangle ink_rect;
    PangoGlyphString *glyphs = pango_glyph_string_new();
    PangoItem* item = (PangoItem*)(items->data);

    pango_shape(*s+item->offset, item->length, &(item->analysis), glyphs);
    Handle<Array> wrappedGlyphString = Array::New(glyphs->num_glyphs);
    //o->Set(String::New("font"), String::New(pango_font_description_to_string(pango_font_describe_with_absolute_size(item->analysis.font))));
    o->Set(String::New("rawGlyphString"), External::Wrap(glyphs));
    o->Set(String::New("font"), External::Wrap(item->analysis.font));

    for (int i = 0 ; i < glyphs->num_glyphs; i++) {
      PangoGlyphInfo g = glyphs->glyphs[i];
      PangoGlyphInfo* g_copy = (PangoGlyphInfo*)malloc(sizeof(PangoGlyphInfo));
      memcpy(g_copy, &g, sizeof(g));
      g_copy->geometry = g.geometry;
      pango_font_get_glyph_extents(item->analysis.font, g.glyph, &ink_rect, NULL);
      Handle<Object> wrappedGlyph = Object::New();
      wrappedGlyph->Set(String::New("rawGlyph"), External::Wrap(g_copy));

      wrappedGlyph->Set(String::New("glyph"), Integer::New(g.glyph));
      wrappedGlyph->Set(String::New("x"), Integer::New(ink_rect.x));
      wrappedGlyph->Set(String::New("y"), Integer::New(ink_rect.y));
      wrappedGlyph->Set(String::New("glyphHeight"), Integer::New(ink_rect.height));
      wrappedGlyph->Set(String::New("ascent"), Integer::New(PANGO_ASCENT(ink_rect)));
      wrappedGlyph->Set(String::New("descent"), Integer::New(PANGO_DESCENT(ink_rect)));
      wrappedGlyph->Set(String::New("glyphWidth"), Integer::New(ink_rect.width));
      wrappedGlyph->Set(String::New("shapedWidth"), Integer::New(g.geometry.width));
      wrappedGlyph->Set(String::New("xOffset"), Integer::New(g.geometry.x_offset));
      wrappedGlyph->Set(String::New("yOffset"), Integer::New(g.geometry.y_offset));

      wrappedGlyphString->Set(Integer::New(i), wrappedGlyph);
    }
    o->Set(String::New("glyphs"), wrappedGlyphString);
    o->Set(String::New("totalWidth"), Integer::New(pango_glyph_string_get_width(glyphs)));

    items = items->next;
    //pango_glyph_string_free(glyphs);
    arr->Set(Integer::New(ii++),o);

  }
  return scope.Close(arr);
}

Pango::Pango(): ObjectWrap() {
  _pangocontext = pango_font_map_create_context(pango_cairo_font_map_get_default());
}

Pango::~Pango() {
  if (_pangocontext) 
    g_object_unref(_pangocontext);
  _pangocontext = NULL;
}
