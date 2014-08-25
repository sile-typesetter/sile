local prefix = "/usr/local/lib/sile"
local exec = "/usr/local/bin/sile"

local errors = 0
print("Testing lua dependencies..\n")
for _,mod in ipairs({"lgi";"lpeg"; "epnf";"std";"lxp";"cassowary";"repl"}) do
    local has_mod = pcall(require, mod)
    if not has_mod then
        print("! Could not load lua module "..mod)
        errors = 1
    end
end
if errors == 1 then
    print("\nPlease consult the README file.\n")
    os.exit(errors)
end
print("OK. Installing.\n");    

if not os.execute("install -d "..prefix) then
    print("! Could not create directory "..prefix);
    os.exit(1)
end

if not os.execute("cp -ar classes core packages languages /usr/local/lib/sile") then
    print("! Could not copy core files to "..prefix)
    os.exit(1)
end
print("Installed SILE libraries to "..prefix)

if not os.execute("cp sile "..exec) then
    print("! Could not install SILE executable to "..exec)
    os.exit(1)
end
print("Installed SILE binary to "..exec)
print("Installation successful!\n")
