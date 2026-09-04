-- Aranese is a Pyrenean "Gascon" variety of the Occitan language, spoken in
-- the Val d'Aran and in a few places in northwestern Catalonia. It is one of
-- the "official" languages recognized by the Parliament of Catalonia.

-- TeX hyphenation patterns for Occitan are "supposed to be valid for all the
-- Occitan variants spoken and written in the wide area called 'Occitanie' by
-- the French. It ranges from the Val d'Aran within Catalunya (...)"
local hyphens = require("languages.oc.hyphens-tex")
SILE.hyphenator.languages["oc-aranes"] = hyphens

-- Aranese slightly differs from standard Occitan however:
-- While it often uses French-style guillemets for primary quotes, it omits the
-- punctuation spaces («...») used in (modern revivals of) standard Occitan.
-- This is not fully authoritative (some linguists advocate for the use of the
-- curly braces for primary quotes in Aranese, under the influence ofn Spanish
-- and Catalan), but at least that's what "Pedagogia - Portau deus ensenhaires
-- d'occitan", a website promoting Occitan, says.
-- Examples in "Nòrmes ortogràfiques der aranés" (1982, provisional text) also
-- show the use of French-style guillemets without punctuation spaces, and no
-- spaces either before "high" punctuation marks.
-- Hence, we do not use the French node maker for Aranese, contrary to what we
-- do for standard Occitan.
