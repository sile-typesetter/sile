start
  = additive

additive
  = left:multiplicative ws* "+" ws* right:additive ws* { return left + right; }
  / left:multiplicative ws* "-" ws* right:additive ws* { return left - right; }
  / m:multiplicative ws* { return m; }

multiplicative
  = left:primary ws* "*" ws* right:multiplicative ws* { return left * right; }
  / left:primary ws* "/" ws* right:multiplicative ws* { return left / right; }
  / p:primary ws* { return p; }

ws
 = [' '\t\r\n]

primary
  = dimensioned_string
  / percentage
  / function
  / float
  / "(" additive:additive ")" { return additive; }

dimensioned_string
  = float:float " "* unit:units { return SILE.toPoints(float, unit) }

units
  = "mm" / "cm" / "in"

percentage
  = string:[0-9\.]+ "%" { return SILE.toPoints(string.join(""), "%", SILE.documentState._dimension); }

float
  = digits:[0-9\.]+ { return parseFloat(digits.join("")); }

function
  = f:( "top" / "left" / "bottom" / "right" / "width" / "height" ) "(" identifier:identifier ")" { return SILE.getFrame(identifier)[f]() }

identifier
  = [a-z_0-9]+