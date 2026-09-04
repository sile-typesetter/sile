SILE.nodeMakers.gl = pl.class(SILE.nodeMakers.unicode)

-- Real Academia Galega (RAG), _Normas ortográficas e morfolóxicas do idioma
-- galego,_ 20th ed., 2005, ISBN 978-84-87987-51-9, §3.2
-- (https://ilg.usc.gal/corrector/docs/normas_galego_2003.pdf)
-- "Cando un guión que separa dúas palabras ou dous membros dunha palabra
-- complexa coincide en final de liña, cómpre repetilo ao comezo da liña
-- seguinte: _dicionario galego-/-inglés._"
-- So Galician hyphenation rules require that when a break occurs at an
-- explicit (lexical) hyphen, the hyphen gets repeated on the next line,
-- following the same rule as in Spanish and Portuguese.
SILE.nodeMakers.gl.hasFeatureRepeatedHyphen = true

local hyphens = require("languages.gl.hyphens-tex")
SILE.hyphenator.languages["gl"] = hyphens
