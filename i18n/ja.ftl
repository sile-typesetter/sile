# some translations are likely tentative

# -- Usual book sections
appendix    = 付録
prechapter  = 第
postchapter = 章
prepart     = 第
postpart    = 部

# -- Other captions
figure = 図
table  = 表
proof  = 証明

# -- TOC-like headers
tableofcontents-title = 目次
index = 索引
listoffigures = 図目次
listoftables = 表目次

# -- Other usual headers
abstract = 概要
bibliography = 参考文献
glossary = 用語集
preface = 前書き
references = 参考文献

# -- Miscellaneous
# page =
# see =
# see-also =
tableofcontents-not-generated = Rerun SILE to process the table of contents!

# -- Bibliography stuff
# bibliography-and =
bibliography-edited-by = { $name }
bibliography-et-al = et al.
bibliography-translated-by = { $name }

# -- Assembling rules
appendix-template = { appendix } { $number }
# N.B. Contain thin nonbreaking space (U+202F) around the number
chapter-template = { prechapter } { $number } { postchapter }
part-template = { prepart } { $number } { postpart }
