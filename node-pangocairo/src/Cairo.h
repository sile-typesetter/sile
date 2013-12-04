#include "PangoCairo.h"

typedef enum {
  CANVAS_TYPE_IMAGE,
  CANVAS_TYPE_PDF
} canvas_type_t;

class Cairo: public ObjectWrap {
  public:
    int width;
    int height;
    canvas_type_t type;
    static Persistent<FunctionTemplate> constructor;
    static void Initialize(Handle<Object> target);
    static Handle<Value> New(const Arguments &args);
    static Handle<Value> Save(const Arguments &args);
    static Handle<Value> Restore(const Arguments &args);
    static Handle<Value> SetSourceRGB(const Arguments &args);
    static Handle<Value> SetSourceRGBA(const Arguments &args);
    static Handle<Value> MoveTo(const Arguments &args);
    static Handle<Value> SelectFontFace(const Arguments &args);
    static Handle<Value> SetFontSize(const Arguments &args);
    static Handle<Value> ShowText(const Arguments &args);
    static Handle<Value> ShowGlyphString(const Arguments &args);
    static Handle<Value> ShowPage(const Arguments &args);
    static Handle<Value> ShowAGlyph(const Arguments &args);
    static Handle<Value> Rectangle(const Arguments &args);
    static Handle<Value> DrawPNG(const Arguments &args);

    static Handle<Value> Finish(const Arguments &args);

    Cairo(int width, int height, canvas_type_t type, char* filename);


  private:
    ~Cairo();
    cairo_surface_t *_surface;
    cairo_t *_cairo;
};

