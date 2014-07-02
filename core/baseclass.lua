SILE.Commands = {}
function SILE.registerCommand (name, f) SILE.Commands[name] = f end

SILE.baseClass = std.object {
  registerCommands = (function()
    local commandStack = {};
    SILE.registerCommand("define", function (options, content)
      SILE.registerCommand(options["command"], function(o,c)
        --local prevState = SILE.documentState;
        --SILE.documentState = std.tree.clone( prevState )
        table.insert(commandStack, c)
        SILE.process(content)
        --SILE.documentState = prevState
      end)
    end)

    SILE.registerCommand("comment", function(o,c) end);
    SILE.registerCommand("process", function()
      SILE.process(table.remove(commandStack));
    end)

    SILE.registerCommand("script", function(options, content)
      if (options["src"]) then 
        require(options["src"])
      else 
        p,e = loadstring(content[1])
        if not p then SU.error(e) end
        p()
      end
    end)

    SILE.registerCommand("include", function(options, content)
        SILE.readFile(options["src"]);
    end)

    SILE.registerCommand("pagetemplate", function (options, content) 
      SILE.documentState.thisPageTemplate = { frames = {} };
      SILE.process(content);
      SILE.documentState.thisPageTemplate.firstContentFrame = SILE.getFrame(options["first-content-frame"]);
      SILE.typesetter:initFrame(SILE.documentState.thisPageTemplate.firstContentFrame);
    end)

    SILE.registerCommand("frame", function (options, content)
      local spec = {
        id = options.id,
        next = options.next,
        balanced = (options.balanced or 0),
        top = options.top and function() return SILE.parseComplexFrameDimension(options.top, "h") end,
        bottom = options.bottom and function() return SILE.parseComplexFrameDimension(options.bottom, "h") end,
        left = options.left and function() return SILE.parseComplexFrameDimension(options.left, "w") end,
        right = options.right and function() return SILE.parseComplexFrameDimension(options.right, "w") end,
        width = options.width and function() return SILE.parseComplexFrameDimension(options.width, "w") end,
        height = options.height and function() return SILE.parseComplexFrameDimension(options.height, "h") end,
      };
      SILE.documentState.thisPageTemplate.frames[options.id] = SILE.newFrame(spec);
    end)

    SILE.registerCommand("penalty", function(options, content)
      SILE.typesetter:pushPenalty({ flagged= tonumber(options.flagged), penalty = tonumber(options.penalty) })
    end)

    SILE.registerCommand("glue", function(options, content) 
      SILE.typesetter:pushGlue({ 
        width = SILE.length.new({ length = SILE.parseComplexFrameDimension(options.width, "w"), stretch = tonumber(options.stretch), shrink = tonumber(options.shrink) })
      })
    end)

    SILE.registerCommand("skip", function(options, content)
      SILE.typesetter:leaveHmode();
      SILE.typesetter:pushVglue({ height = SILE.length.new({ length = SILE.parseComplexFrameDimension(options.height, "h"), stretch = SILE.parseComplexFrameDimension(options.stretch or "0", "h") or 0, shrink = tonumber(options.shrink) or 0 }) })
    end)
  end),

  pageTemplate = std.object { frames= {}, firstContentFrame= nil },
  loadPackage = function(self, packname, args)
    local pack = require("packages/"..packname)
    self:mapfields(pack.exports)
    if pack.init then
      pack.init(self, args)
    end
  end,
  init = function(self)
    SILE.outputter.init(self); 
    self:registerCommands();
    return self:initialFrame();
  end,
  initialFrame= function(self)
    SILE.documentState.thisPageTemplate = self.pageTemplate {};
    return SILE.documentState.thisPageTemplate.firstContentFrame;
  end,
  declareFrame = function (self, id, spec)
    local fW = function (val) return function() return SILE.parseComplexFrameDimension(val, "w"); end end
    local fH = function (val) return function() return SILE.parseComplexFrameDimension(val, "h"); end end
    self.pageTemplate.frames[id] = SILE.newFrame({
      next= spec.next,
      left= spec.left and fW(spec.left),
      right= spec.right and fW(spec.right),
      top= spec.top and fH(spec.top),
      bottom= spec.bottom and fH(spec.bottom),
      height = spec.height and fH(spec.height),
      width = spec.width and fH(spec.width),
      id = id
    });
  end,
  newPage = function(self) 
    SILE.outputter:newPage();
    -- Any other output-routiney things will be done here by inheritors
    return self:initialFrame();
  end,
  endPage= function()
    SILE.typesetter:leaveHmode();
    -- Any other output-routiney things will be done here by inheritors
  end,
  finish = function(self)
    self:endPage();
    SILE.typesetter:shipOut(0);
    SILE.outputter:finish()
  end,
  newPar = function(typesetter)
    typesetter:pushVglue(SILE.settings.get("document.lineskip"))
    typesetter:pushGlue(SILE.settings.get("document.parindent"))
  end,
  options= { 
    papersize= function(size)
      _, _, x, y = string.find(size, "(.+)%s+x%s+(.+)")
      if x then
        SILE.documentState.paperSize ={ SILE.toPoints(x), SILE.toPoints(y) };
      elseif (SILE.paperSizes[size]) then
        SILE.documentState.paperSize = SILE.paperSizes[size];
      else
        SU.error("Unknown paper size "..size);
      end
    end
  }
}