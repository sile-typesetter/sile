
The patterns in this folder are derived from the [TeX hyphenation patterns][TeX hyphenation repository](https://github.com/hyphenation/tex-hyphen).

The **sources** subfolder contains the original patterns in TeX format (for reference and easier comparison with the original patterns if the latter are updated).

The **scripts** subfolder contains Lua scripts for converting the TeX patterns to Lua format.
The conversion is very naive and may not work for all patterns.
It was obtained by running the following command in this folder:

```shell
source convert.sh
```

## License

The patterns are licensed under MIT, LPPL, or sometimes a dual MIT/LPPL license.
See the individual pattern files for details.

The converted patterns are licensed under the same license as the original patterns.
