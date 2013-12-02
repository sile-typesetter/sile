#include "PangoCairo.h"
#include "PangoAttrList.h"
#include <string.h>

Persistent<FunctionTemplate> NodePangoAttrList::constructor;

void
NodePangoAttrList::Initialize(Handle<Object> target) {
  HandleScope scope;

  // Constructor
  constructor = Persistent<FunctionTemplate>::New(FunctionTemplate::New(NodePangoAttrList::New));
  constructor->InstanceTemplate()->SetInternalFieldCount(1);
  constructor->SetClassName(String::NewSymbol("PangoAttrList"));

  // Prototype
  //Local<ObjectTemplate> proto = constructor->PrototypeTemplate();
  NODE_SET_PROTOTYPE_METHOD(constructor, "insert", Insert);

  target->Set(String::NewSymbol("PangoAttrList"), constructor->GetFunction());
}

Handle<Value>
NodePangoAttrList::New(const Arguments &args) {
  HandleScope scope;
  NodePangoAttrList *p = new NodePangoAttrList();
  p->Wrap(args.This());
  return args.This();
}

Handle<Value>
NodePangoAttrList::Insert(const Arguments &args) {
  HandleScope scope;
  v8::String::Utf8Value type (args[0]->ToString());
  NodePangoAttrList *l = ObjectWrap::Unwrap<NodePangoAttrList>(args.This());
  if (!strcmp(*type,"language")) {
    v8::String::Utf8Value lang (args[1]->ToString());
    pango_attr_list_insert(l->_attrlist, pango_attr_language_new(pango_language_from_string(*lang)));
  } else if (!strcmp(*type, "family")) {
    v8::String::Utf8Value lang (args[1]->ToString());
    pango_attr_list_insert(l->_attrlist, pango_attr_family_new(*lang));
  } else if (!strcmp(*type, "size")) {
    pango_attr_list_insert(l->_attrlist, pango_attr_size_new(args[1]->IntegerValue() * PANGO_SCALE));
  } else if (!strcmp(*type, "weight")) {
    pango_attr_list_insert(l->_attrlist, pango_attr_weight_new((PangoWeight)args[1]->IntegerValue()));
  } else {
    printf("Unknown attribute class\n");
  }
  return v8::Boolean::New(true);
}


NodePangoAttrList::NodePangoAttrList(): ObjectWrap() {
  _attrlist = pango_attr_list_new();
}

NodePangoAttrList::~NodePangoAttrList() {
  if (_attrlist) 
    pango_attr_list_unref(_attrlist);
  _attrlist = NULL;
}
