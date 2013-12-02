#include "PangoCairo.h"

class NodePangoAttrList: public ObjectWrap {
  public:
    static Persistent<FunctionTemplate> constructor;
    static void Initialize(Handle<Object> target);
    static Handle<Value> New(const Arguments &args);
    static Handle<Value> Insert(const Arguments &args);
    NodePangoAttrList();
    PangoAttrList *_attrlist;

  private:
    ~NodePangoAttrList();
};

