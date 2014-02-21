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

    SILE.registerCommand("font", function(options, content)
      local prevState = SILE.documentState;
      if (content[1]) then
        SILE.documentState = std.tree.clone( prevState )
      end
      if (options.family)  then SILE.documentState.fontFamily = options.family end
      if (options.size)  then SILE.documentState.fontSize = options.size end
      if (options.weight)  then SILE.documentState.fontWeight = options.weight end
      if (options.style)  then SILE.documentState.fontStyle = options.style end
      if (options.variant)  then SILE.documentState.fontVariant = options.variant end
      if (options.language)  then SILE.documentState.language = options.language end
      if (content[1]) then 
        SILE.process(content)
        SILE.documentState = prevState
      end
    end)

    SILE.registerCommand("penalty", function(options, content)
      SILE.typesetter:pushPenalty({ flagged= tonumber(options.flagged), penalty = tonumber(options.penalty) })
    end)

    SILE.registerCommand("glue", function(options, content) 
      SILE.typesetter:pushGlue({ 
        width = SILE.length.new({ length = tonumber(options.width), stretch = tonumber(options.stretch), shrink = tonumber(options.shrink) })
      })
    end)

    SILE.registerCommand("skip", function(options, content)
      SILE.typesetter:leaveHmode();
      SILE.typesetter:pushVglue({ height = SILE.length.new({ length = tonumber(options.height), stretch = tonumber(options.stretch) or 0, shrink = tonumber(options.shrink) or 0 }) })
    end)
  end),

  settings = { widowPenalty= 5000, clubPenalty= 5000 },
  pageTemplate = std.object { frames= {}, firstContentFrame= nil },
  state = {
    parindent = SILE.nodefactory.newGlue({ width= SILE.length.new({length = 11, stretch= 0, shrink= 0})}),
    baselineSkip = SILE.nodefactory.newVglue({ height= SILE.length.new({length = 13, stretch= 2, shrink= 0})}),
    lineSkip = SILE.nodefactory.newVglue({ height= SILE.length.new({length = 2, stretch= 0, shrink= 0}) }),
  },
  init = function(self)
    SILE.outputter.init(self); 
    self:registerCommands();
    SILE.documentState.fontFamily = "Gentium";
    SILE.documentState.fontSize = 10;
    SILE.documentState.fontWeight = 200;
    SILE.documentState.fontStyle = "normal";
    SILE.documentState.language = "en";
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
      left= fW(spec.left),
      right= fW(spec.right),
      top= fH(spec.top),
      bottom= fH(spec.bottom)
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
    typesetter:pushVglue(SILE.documentState.documentClass.state.lineSkip);
    typesetter:pushGlue( SILE.documentState.documentClass.state.parindent );
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