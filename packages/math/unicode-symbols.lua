--- Extend the unicode-symbols-generated symbols with additional aliases.
local mathml_entities = require("packages.math.mathml-entities")
local symbols = mathml_entities.symbols
local operatorDict = mathml_entities.operatorDict
local atoms = require("packages.math.atoms")

--- Add aliases for symbols that have multiple names.
-- We check that the alias is already defined in the generated dictionary,
-- and that the symbol is not defined.
-- If not, we raise an error: our operator dictionary is probably broken.
-- @tparam string symbol Symbol needing an alias
-- @tparam string alias  Existing alias
local function addAlias (symbol, alias)
   if symbols[symbol] then
      SU.error("Symbol " .. symbol .. " already defined (operator dictionary is probably broken)")
   end
   if not symbols[alias] then
      SU.error("Symbol " .. alias .. " not defined (operator dictionary is probably broken)")
   end
   symbols[symbol] = symbols[alias]
end

-- \% in TeX is the regular ordinary mathpercent symbol (U+0025)
addAlias("%", "mathpercent")

-- Additional TeX-like operators
addAlias("dots", "unicodeellipsis")
addAlias("ldots", "unicodeellipsis")
addAlias("cdots", "unicodecdots")
addAlias("implies", "Longrightarrow")
addAlias("iff", "Longleftrightarrow")
addAlias("vec", "overrightarrow")

-- Alias from unicode-math/um-code-epilogue.dtx
-- (Symbols with multiple names)
addAlias("le", "leq")
addAlias("ge", "geq")
addAlias("neq", "ne")
addAlias("triangle", "bigtriangleup")
addAlias("bigcirc", "mdlgwhtcircle")
addAlias("circ", "vysmwhtcircle")
addAlias("bullet", "smblkcircle")
addAlias("yen", "mathyen")
addAlias("sterling", "mathsterling")
addAlias("diamond", "smwhtdiamond")
addAlias("emptyset", "varnothing")
addAlias("hbar", "hslash")
addAlias("land", "wedge")
addAlias("lor", "vee")
addAlias("owns", "ni")
addAlias("gets", "leftarrow")
addAlias("mathring", "ocirc")
addAlias("lnot", "neg")

-- Additional aliases from LaTeX / AMS
-- (Mix from unicode-math and AMS names in unicode.xml
addAlias("colon", "mathcolon")
addAlias("eth", "matheth")
addAlias("AA", "Angstrom")
addAlias("bbsum", "Bbbsum")
addAlias("blacksquare", "mdlgblksquare")
addAlias("square", "mdlgwhtsquare")
addAlias("lozenge", "mdlgwhtlozenge")
addAlias("circlearrowleft", "acwcirclearrow")
addAlias("circlearrowright", "cwcirclearrow")
addAlias("blacklozenge", "mdlgblklozenge")

-- Additional aliases for "accents"
addAlias("overline", "overbar")
addAlias("underline", "mathunderbar")
addAlias("underbar", "mathunderbar")
addAlias("overrightharpoon", "rightharpoonaccent")
addAlias("overleftharpoon", "leftharpoonaccent")
-- Caveat emptor:
-- For some of them, TeX would consider one to be stretchy, the other not...
-- It's completely insane to still have to deal with this in the 21st century,
-- so let's not bother and just make them aliases to at least get something working for now.
addAlias("utilde", "wideutilde")
addAlias("widecheck", "check")
addAlias("widehat", "hat")
addAlias("widetilde", "tilde")

-- (Original-TeX) TeX-like greek letters
symbols.alpha = "α"
symbols.beta = "β"
symbols.gamma = "γ"
symbols.delta = "δ"
symbols.epsilon = "ϵ"
symbols.varepsilon = "ε"
symbols.zeta = "ζ"
symbols.eta = "η"
symbols.theta = "θ"
symbols.vartheta = "ϑ"
symbols.iota = "ι"
symbols.kappa = "κ"
symbols.lambda = "λ"
symbols.mu = "μ"
symbols.nu = "ν"
symbols.xi = "ξ"
symbols.omicron = "ο"
symbols.pi = "π"
symbols.varpi = "ϖ"
symbols.rho = "ρ"
symbols.varrho = "ϱ"
symbols.sigma = "σ"
symbols.varsigma = "ς"
symbols.tau = "τ"
symbols.upsilon = "υ"
symbols.phi = "ϕ"
symbols.varphi = "φ"
symbols.chi = "χ"
symbols.psi = "ψ"
symbols.omega = "ω"
symbols.Alpha = "Α"
symbols.Beta = "Β"
symbols.Gamma = "Γ"
symbols.Delta = "Δ"
symbols.Epsilon = "Ε"
symbols.Zeta = "Ζ"
symbols.Eta = "Η"
symbols.Theta = "Θ"
symbols.Iota = "Ι"
symbols.Kappa = "Κ"
symbols.Lambda = "Λ"
symbols.Mu = "Μ"
symbols.Nu = "Ν"
symbols.Xi = "Ξ"
symbols.Omicron = "Ο"
symbols.Pi = "Π"
symbols.Rho = "Ρ"
symbols.Sigma = "Σ"
symbols.Tau = "Τ"
symbols.Upsilon = "Υ"
symbols.Phi = "Φ"
symbols.Chi = "Χ"
symbols.Psi = "Ψ"
symbols.Omega = "Ω"
-- Other TeX-like greek symbols
symbols.digamma = "ϝ" -- Supported by TeMML, MathJax, and LaTeX's unicode-math
symbols.Digamma = "Ϝ" -- Supported by LaTeX's unicode-math

-- In xml-entities's unicode.xml, the minus-hyphen (U+002D) has different
-- properties from to the minus sign (U+2212).
-- In our TeX-like syntax, they should however lead to the same symbol.
operatorDict["-"] = operatorDict["−"]

-- Override the atom type of a symbol in the operator dictionary.
-- @tparam string symbol Symbol to override
-- @tparam string atom   New atom type
local function overrideAtom (symbol, atom)
   if not symbols[symbol] then
      SU.error("Symbol " .. symbol .. " not defined (operator dictionary is probably broken)")
   end
   operatorDict[symbols[symbol]].atom = atom
end

-- In xml-entities's unicode.xml, we derived "ord" for U+034D COMBINING LEFT RIGHT ARROW BELOW
-- as is doesn't have a "D" class (diacritic)
-- Actually it's not the fault of xml-entities, such a character is not covered in the latest
-- Unicode MathClass file: https://www.unicode.org/Public/math/revision-15/MathClassEx-15.html
-- It should clearly be a "botaccent" however, for \underleftrightarrow to work as do other accents.
-- Note the U+20E1 COMBINING LEFT RIGHT ARROW ABOVE has s a "D" and we thus mapped to an "accent",
-- used for \overleftrightarrow, so the asymmetry is at least weird.
-- For future reference, see also https://github.com/w3c/xml-entities/issues/12 but it's probably
-- not where the discussion should happen...
overrideAtom("underleftrightarrow", atoms.types.botaccent)

return {
   symbols = symbols,
   operatorDict = operatorDict,
}
