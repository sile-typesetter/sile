#!/usr/bin/env bash

: ${source_branch:=tex-hyphenation-sources}

git ls-tree -r --name-only $source_branch |
   grep 'sources/hyph-.*tex$' |
   while read tex_src; do
      lang=$(<<< "$tex_src" sed -E 's/[^-]+-//;s/.tex$//')
      git show $source_branch:$tex_src |
         lua build-aux/transpile-tex-hyphen-patterns.lua \
         > hyphens/tex/$lang.lua
   done
