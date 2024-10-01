# Language support comments

Supporting a language in SILE involves some combination of:

* A base module (required)
* A hyphenation patterns module
* Localization strings

## Hyphenation patterns

Hyphenation rules are typically handled via patterns for the Knuth-Liang hyphenation algorithm.

The patterns respect the following format (with all fields being optional):

```lua
return {
   -- If derived from some other patterns
   input = { "..." }, -- Not yet supported
   -- Typesetting parameters
   hyphenmins = {
      typesetting = {left = ..., right = ...},
      generation = {left = ..., right = ...},
   },
   -- Hyphenation patterns
   patterns = {
      "...",
   },
   -- Exceptions (words with hyphens)
   exceptions = {
      "...",
   },
}
```

Most of our pattern modules are are import from [TeX patterns](https://github.com/hyphenation/tex-hyphen).
The sources of these is reflected in the module filenames: ones ending in `-tex` are automatically transpiled from TeX sources.
A few languages have pattern modules that are unique to SILE.
These may be hand coded, contributed directly, or hand modified from other sources.

A branch **tex-hyphenation-sources** is available in SILE's Git repository that contains the original patterns in TeX format.
They are not distributed with SILE but seeing the versions we imported can be useful for reference and easier comparison with the original patterns if the latter are updated.
The **build-aux** subfolder contains an import script and Lua transpiler for converting the TeX patterns to Lua format.
The conversion is very naive and may not work for all patterns.

## License

The patterns are licensed under MIT, LPPL, or sometimes a dual MIT/LPPL license.
See the individual pattern files for details and authorship information.

The converted patterns are licensed under the same license as the original patterns.
