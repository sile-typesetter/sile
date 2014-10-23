-- Example plugin that demonstrates the objects available to a
-- plugin, as well as the methods that a plugin should make use
-- of

-- Adding methods and properties to the repl object adds them to
-- the REPL object loading the plugin.  If such a method or property
-- already exists, the current plugin will fail to load.
function repl:newmethod(...)
end

-- Adding methods to the before object causes them to be called
-- before the actual method itself.  If the method being added
-- (in this case displayresults) does not exist on the REPL object
-- loading this plugin, the current plugin will fail to load.
function before:displayresults(results)
end

-- Adding methods to the after object causes them to be called
-- after the actual method itself.  If the method being added
-- (in this case displayresults) does not exist on the REPL object
-- loading this plugin, the current plugin will fail to load.
function after:displayresults(results)
end

-- Adding methods to the around object causes them to be called
-- instead of the original method of the same name.  The new
-- method receives all of the arguments that the original would,
-- except it also receives the original method as the first argument.
-- This way, the new method may invoke the original as it pleases.
-- If the method being added (in this case displayresults) does not exist on
-- the REPL object loading this plugin, the current plugin will fail to load.
function around:evalute(orig, chunk)
end

-- Adding methods to the override object causes them to be called
-- instead of the original method of the same name.  If the method being added
-- (in this case displayresults) does not exist on the REPL object loading this
-- plugin, the current plugin will fail to load.
function override:name()
  return 'Plugin!'
end
