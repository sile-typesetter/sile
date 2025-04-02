--- French language rules
-- @submodule languages
local unicode = require("languages.unicode")

local language = pl.class(unicode)
language._name = "fr"

function language:setupNodeMaker ()
   self.nodemaker = require("languages.fr.nodemaker")
end

function language.declareSettings (_)
   local function computeSpaces ()
      -- Computes:
      --  -  regular inter-word space,
      --  -  half inter-word fixed space,
      --  -  "guillemet space", as defined in LaTeX's babel-french which is based
      --     on Thierry Bouche's recommendations,
      --  These should be usual for France and Canada. The Swiss may prefer a thin
      --  space for guillemets, that's why we are having settings hereafter.
      local enlargement = SILE.settings:get("shaper.spaceenlargementfactor")
      local stretch = SILE.settings:get("shaper.spacestretchfactor")
      local shrink = SILE.settings:get("shaper.spaceshrinkfactor")
      return {
         colonspace = SILE.types.length(enlargement .. "spc plus " .. stretch .. "spc minus " .. shrink .. "spc"),
         thinspace = SILE.types.length((0.5 * enlargement) .. "spc"),
         guillspace = SILE.types.length(
            (0.8 * enlargement) .. "spc plus " .. (0.3 * stretch) .. "spc minus " .. (0.8 * shrink) .. "spc"
         ),
      }
   end

   -- TODO add hooks tot he relevant settings computed here to update these values
   local spaces = computeSpaces()
   -- NOTE: We are only doing it at load time. We don't expect the shaper settings to be often
   -- changed arbitrarily _after_ having selected a language...
   SILE.settings:declare({
      parameter = "languages.fr.colonspace",
      type = "kern",
      default = SILE.types.node.kern(spaces.colonspace),
      help = "The amount of space before a colon, theoretically a non-breakable, shrinkable, stretchable inter-word space",
   })

   SILE.settings:declare({
      parameter = "languages.fr.thinspace",
      type = "kern",
      default = SILE.types.node.kern(spaces.thinspace),
      help = "The amount of space before high punctuations, theoretically a fixed, non-breakable space, around half the inter-word space",
   })

   SILE.settings:declare({
      parameter = "languages.fr.guillspace",
      type = "kern",
      default = SILE.types.node.kern(spaces.guillspace),
      help = "The amount of space applying to guillemets, theoretically smaller than a non-breakable inter-word space, with reduced stretchability",
   })

   SILE.settings:declare({
      parameter = "languages.fr.debugspace",
      type = "boolean",
      default = false,
      help = "If switched to true, uses large spaces instead of the regular punctuation ones",
   })
end

return language
