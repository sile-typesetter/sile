local registry = pl.class()
registry.type = "registry"
registry._name = "base"

function registry:_init ()
   if self._name == "base" then
      SU.error("Attempted to initialize base registry")
   end
   local proto = self._name:match("^(%w*)s$")
   self._entry_prototype = SILE.types[proto]
   self._registry = {}
   SU.debug("registries", "Started registry for", self._entry_prototype.type .. "s")
end

function registry:forModule (parent)
   if not SILE.types.module:class_of(parent) and parent ~= SILE then
      SU.error("Attempted to initialize registry for non-module " .. parent)
   end
   local root = self._root_registry or self
   local wrapper = { _root_registry = root }
   setmetatable(wrapper, {
      __index = function (wrapper_, key)
         local _root = wrapper_._root_registry
         if type(_root[key]) == "function" and key ~= "forModule" then
            return function (_, ...)
               return _root[key](_root, parent, ...)
            end
         else
            return _root[key]
         end
      end,
   })
   return wrapper
end

function registry:exists (_parent, name)
   local stack = self._registry[name]
   return stack
end

function registry:push (parent, entry)
   if not self._entry_prototype:class_of(entry) then
      SU.error("Attempted to push an entry in a registry that does not match its type")
   end
   local name = tostring(entry)
   if not self:exists(parent, name) then
      SU.error("Attempted to push an entry into a registry without a registered name")
   end
   table.insert(self._registry[name], entry)
   return entry, #self._registry[name]
end

function registry:clear (parent, name)
   SU.debug("registries", "Clearing active value for", name and name or "*", "from registry")
   if name then
      if not self:exists(parent, name) then
         SU.error("Attempted to clear an entry from a registry that does not exist")
      end
      table.insert(self._registry[name], false)
   else
      for id in self:iterate() do
         self:clear(parent, id)
      end
   end
end

function registry:pull (parent, name, count)
   if not self:exists(parent, name) then
      SU.error(("No entry '%s' exists in %s registry"):format(name, self._name))
   end
   local stack = self._registry[name]
   count = tonumber(count) or 1
   local index = #stack - count + 1
   return stack[index], index
end

function registry:pop (parent, name, count)
   if not self:exists(parent, name) then
      SU.error("Cannot pop '%s' from the registry, never registered."):format(name)
   end
   local stack = self._registry[name]
   local command
   count = tonumber(count) or 1
   SU.debug("registries", function ()
      return ("Popping %d registrations of '%s'"):format(count, name)
   end)
   if count <= #stack then
      for _ = 1, count do
         command = table.remove(stack)
      end
      return command
   else
      SU.error(("Cannot pop %d registrations of '%s', only %d registered."):format(count, name, #stack))
   end
end

function registry:iterate ()
   local ids = pl.tablex.keys(self._registry)
   local i = 0
   return function ()
      i = i + 1
      local id = ids[i]
      if id then
         local stack = self._registry[id]
         return id, stack[#stack]
      end
   end
end

return registry
