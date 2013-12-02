#include "PangoCairo.h"

class Pango: public ObjectWrap {
  public:
    static Persistent<FunctionTemplate> constructor;
    static void Initialize(Handle<Object> target);
    static Handle<Value> New(const Arguments &args);
    static Handle<Value> SetLanguage(const Arguments &args);
    static Handle<Value> ItemizeAndShape(const Arguments &args);

    Pango();

  private:
    ~Pango();
    PangoContext *_pangocontext;
};

