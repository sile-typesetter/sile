set ignore-comments := true
set shell := ["zsh", "+o", "nomatch", "-ecu"]
set unstable := true
set script-interpreter := ["zsh", "+o", "nomatch", "-eu"]

_default:
	@just --list --unsorted

nuke-n-pave:
	git clean -dxff -e .husky -e .fonts -e .sources -e node_modules -e target -e completions
	./bootstrap.sh

dev-conf: nuke-n-pave
	./configure --enable-developer-mode --with-system-luarocks --with-system-lua-sources --without-manual --enable-debug
	make

rel-conf: nuke-n-pave
	./configure --enable-developer-mode --with-system-luarocks --with-system-lua-sources --with-manual
	make

perfect:
	make check lint regressions

[private]
[doc('Block execution if Git working tree isn’t pristine.')]
pristine:
	# Ensure there are no changes in staging
	git diff-index --quiet --cached HEAD || exit 1
	# Ensure there are no changes in the working tree
	git diff-files --quiet || exit 1

[private]
[doc('Block execution if we don’t have access to private keys.')]
keys:
	gpg -a --sign > /dev/null <<< "test"

cut-release type: pristine
	make release RELTYPE=type

release semver: pristine
	git describe HEAD --tags | grep -Fx 'v{{semver}}'
	git push --atomic upstream master v{{semver}}
	git push --atomic origin master v{{semver}}
	git push --atomic gitlab master v{{semver}}
	git push --atomic codeberg master v{{semver}}

post-release semver: keys
	gh release download --clobber v{{semver}}
	ls sile-{{semver}}.{pdf,zip,tar.zst} sile-x86_64 sile-vendored-crates-{{semver}}.tar.zst | xargs -n1 gpg -a --detach-sign
	gh release upload v{{semver}} sile*-{{semver}}.asc sile-x86_64.asc

# vim: set ft=just
