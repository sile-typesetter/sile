This folder contains hyphenation patterns for Knuth-Liang hyphenation algorithm.

The patters follow the following format (with all fields being optional):

```lua
return {
   -- If derived from some other patterns
   input = { "..." },
   -- Typesetting parameters
   hyphenmins = {
      typesetting = {left = ..., right = ...},
      generation = {left = ..., right = ...},
   },
   patterns = {
      "...",
   },
   exceptions = {
      "...",
   },
}
```

Patterns are organized in subfolders.
 - **misc** contains patterns specific to SILE or from uncertain origin.
