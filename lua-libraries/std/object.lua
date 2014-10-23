--[[--
 Prototype-based objects.

 This module creates the root prototype object from which every other
 object is descended.  There are no classes as such, rather new objects
 are created by cloning an existing object, and then changing or adding
 to the clone. Further objects can then be made by cloning the changed
 object, and so on.

 Objects are cloned by simply calling an existing object, which then
 serves as a prototype from which the new object is copied.

 All valid objects contain a field `_init`, which determines the syntax
 required to execute the cloning process:

   1. `_init` can be a list of keys; then the unnamed `init_1` through
      `init_m` values from the argument table are assigned to the
      corresponding keys in `new_object`;

         new_object = proto_object {
           init_1, ..., init_m;
           field_1 = value_1,
           ...
           field_n = value_n,
         }

   2. Or it can be a function, in which the arguments passed to the
      prototype during cloning are simply handed to the `_init` function:

        new_object = proto_object (arg, ...)

 Objects, then, are essentially tables of `field\_n = value\_n` pairs:

      > o = Object {
      >>  field_1 = "value_1",
      >>  method_1 = function (self) return self.field_1 end,
      >> }
      > = o.field_1
      value_1
      > o.field_2 = 2
      > function o:method_2 (n) return self.field_2 + n end
      > = o:method_2 (2)
      4

 Normally `new_object` automatically shares a metatable with
 `proto_object`. However, field names beginning with "_" are *private*,
 and moved into the object metatable during cloning. So, adding new
 private fields to an object during cloning will result in a new
 metatable for `new_object` that also contains a copy of all the entries
 in the `proto_object` metatable.

 Note that Object methods are stored in the `\_\_index` field of their
 metatable, and so cannot also use `\_\_index` to lookup references with
 square brackets.  See @{std.container} objects if you want to do that.

 @classmod std.object
]]



-- Surprise!!  The real root object is Container, which has less
-- functionality than Object, but that makes the heirarchy hard to
-- explain, so the documentation pretends this is the root object, and
-- Container is derived from it.  Confused? ;-)


local Container  = require "std.container"
local metamethod = (require "std.functional").metamethod


--- Root object.
--
-- Changing the values of these fields in a new object will change the
-- corresponding behaviour.
-- @table std.object
-- @string[opt="Object"] _type type of Object, returned by @{prototype}
-- @tfield table|function _init a table of field names, or
--   initialisation function, used by @{clone}
-- @tfield nil|table _functions a table of module functions not copied
--   by @{std.object.__call}
return Container {
  _type  = "Object",

  -- No need for explicit module functions here, because calls to, e.g.
  -- `Object.prototype` will automatically fall back metamethods in
  -- `\_\_index`.

  __index = {
    --- Clone this Object.
    -- @function clone
    -- @tparam std.object obj an object
    -- @param ... a list of arguments if `o._init` is a function, or a
    --   single table if `o._init` is a table.
    -- @treturn std.object a clone of `o`
    -- @see __call
    clone = metamethod (Container, "__call"),


    --- Type of an object, or primitive.
    --
    -- It's conventional to organise similar objects according to a
    -- string valued `_type` field, which can then be queried using this
    -- function.
    --
    --     Stack = Object {
    --       _type = "Stack",
    --
    --       __tostring = function (self) ... end,
    --
    --       __index = {
    --         push = function (self) ... end,
    --         pop  = function (self) ... end,
    --       },
    --     }
    --     stack = Stack {}
    --
    --     stack:prototype () --> "Stack"
    --
    -- @function prototype
    -- @param x anything
    -- @treturn string type of `x`
    prototype = Container.prototype.call,


    --- Return `obj` with references to the fields of `src` merged in.
    --
    -- More importantly, split the fields in `src` between `obj` and its
    -- metatable. If any field names begin with `\_`, attach a metatable
    -- to `obj` if it doesn't have one yet, and copy the "private" `\_`
    -- prefixed fields there.
    --
    -- You might want to use this function to instantiate your derived
    -- objct clones when the prototype's `_init` is a function -- when
    -- `_init` is a table, the default (inherited unless you overwrite
    -- it) clone method calls `mapfields` automatically.  When you're
    -- using a function `_init` setting, `clone` doesn't know what to
    -- copy into a new object from the `_init` function's arguments...
    -- so you're on your own.  Except that calling `mapfields` inside
    -- `_init` is safer than manually splitting `src` into `obj` and
    -- its metatable, because you'll pick up fixes and changes when you
    -- upgrade stdlib.
    -- @function mapfields
    -- @tparam table obj destination object
    -- @tparam table src fields to copy int clone
    -- @tparam[opt={}] table map `{old_key=new_key, ...}`
    -- @treturn table `obj` with non-private fields from `src` merged,
    --   and a metatable with private fields (if any) merged, both sets
    --   of keys renamed according to `map`
    mapfields = Container.mapfields.call,


    -- Backwards compatibility:
    type = Container.prototype.call,
  },


  --- Return a @{clone} of this object, and its metatable.
  --
  -- Private fields are stored in the metatable.
  -- @function __call
  -- @param ... arguments for `\_init`
  -- @treturn std.object a clone of the this object.
  -- @see clone


  --- Return a string representation of this object.
  --
  -- First the object type, and then between { and } a list of the
  -- array part of the object table (without numeric keys) followed
  -- by the remaining key-value pairs.
  --
  -- This function doesn't recurse explicity, but relies upon suitable
  -- `__tostring` metamethods in field values.
  -- @function __tostring
  -- @treturn string stringified container representation
  -- @see tostring


  --- Return a shallow copy of non-private object fields.
  --
  -- Used by @{clone} to get the base contents of the new object. Can
  -- be overridden in other objects for greater control of which fields
  -- are considered non-private.
  -- @function __totable
  -- @treturn table a shallow copy of non-private object fields
  -- @see std.table.totable
}
