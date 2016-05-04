---
post_author: Simon Cozens
post_gravatar: 11cdaff4c6f9b290db40f69d3b20caf1
---

The ever-excellent [xkcd][] has produced a table of full-width justification strategies:

![XKCD](http://imgs.xkcd.com/comics/full_width_justification.png)

Naturally, SILE implements support for snake-based justification methods. You will need to check out the relevant [feature branch][]. Simply add

    \script[src=packages/snakes]

(or XML equivalent) to your document to turn on this justification strategy. You can see the result in [`examples/snakes.pdf`](https://github.com/simoncozens/sile/blob/snakes/examples/snakes.pdf), and it looks like this:

![snakes](images/snakes.png)

Because SILE is an extremely flexible typesetting engine, this took less than 20 lines of Lua code to implement.

We have been doing lots of other SILE development too, but snakes are fun.

[xkcd]: http://www.xkcd.com/
[feature branch]: https://github.com/simoncozens/sile/tree/snakes
