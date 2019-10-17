std = "min"
include_files = {
	"**/*.lua",
	"*.rockspec",
	".luacheckrc"
}
exclude_files = {
	"lua_modules",
	"lua-libraries"
}
globals = {
	"SILE",
	"SU",
	"bit32"
}
max_line_length = false
