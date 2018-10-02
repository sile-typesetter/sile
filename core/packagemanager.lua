local catalogueURL = "https://raw.githubusercontent.com/simoncozens/sile-packages/master/packages.lua"
local packageHome = SYSTEM_SILE_PATH .. "/packagemanager/"
local catalogueHome = packageHome .. "catalogue.lua"
local installedCatalogue = packageHome .. "installed.lua"

local http = require("ssl.https")
local recentlyUpdated = false
local recentlyReloaded = false
local origcpath = package.cpath -- for idempotence
local origpath = package.path

SILE.PackageManager = {
  installed = {},
  Catalogue = {}
}

local function loadInSandbox(untrusted_code)
  if _ENV then -- simple Lua 5.2 version check
    local env = {}
    local untrusted_function, message = load(untrusted_code, nil, 't', env)
    if not untrusted_function then return nil, message end
    return pcall(untrusted_function)
  else
    if untrusted_code:byte(1) == 27 then return nil, "binary bytecode prohibited" end
    local untrusted_function, message = loadstring(untrusted_code)
    if not untrusted_function then return nil, message end
    setfenv(untrusted_function, env)
    return pcall(untrusted_function)
  end
end

local function dumpTable(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dumpTable(v) .. ','
      end
      return s .. '} '
   else
      -- This only works because we are only storing strings!
      return '"' .. tostring(o) .. '"'
   end
end

local function fixupPaths()
  local paths = ""
  local cpaths = ""
  for k,v in pairs(SILE.PackageManager.installed) do
    paths = paths .. packageHome .. k .. '/?.lua;'
    cpaths = cpaths .. packagehome .. k .. "/?."..SHARED_LIB_EXT.. ";"
  end
  package.path = origpath:gsub("?.lua","?.lua;"..paths,1)
  package.cpath = origcpath .. ";" .. cpaths
end

local function saveInstalled()
  local dump = dumpTable(SILE.PackageManager.installed)
  local fh,e = io.open(installedCatalogue, "w")
  if e then
    SU.error("Could not write installed package list at"..installedCatalogue..": "..e)
  end
  fh:write("return "..dump)
  fh:close()
  fixupPaths()
end

local function updateCatalogue ()
  if not lfs.attributes(packageHome) then
    if not lfs.mkdir(packageHome) then
      SU.error("Error making package manager home directory: "..packageHome)
    end
  end
  print("Loading catalogue from "..catalogueURL)
  result, statuscode, content = http.request(catalogueURL)
  if statuscode ~= 200 then
    SU.error("Could not load catalogue from "..catalogueURL..": "..statuscode)
  end
  local fh,e = io.open(catalogueHome, "w")
  if e then
    SU.error("Could not write package catalogue at"..catalogueHome..": "..e)
  end
  print("Writing "..(#result).." bytes to "..catalogueHome)
  fh:write(result)
  fh:close()
  recentlyUpdated = true
  recentlyReloaded = false
end

local function loadInstalledCatalogue()
   f = io.open(installedCatalogue, "r")
   if f~=nil then
    local contents = f:read("*all")
    success,res = loadInSandbox(contents)
    if not success then
      SU.error("Error loading installed package list: "..res)
    end
    SILE.PackageManager.installed = res
   end
end

local function reloadCatalogue()
   local f=io.open(catalogueHome,"r")
   if f~=nil then
    local contents = f:read("*all")
    local success,res = loadInSandbox(contents)
    if not success then
      SU.error("Error loading package catalogue: "..res)
    end
    SILE.PackageManager.Catalogue = res
   end
   loadInstalledCatalogue()
   print("Package catalogue reloaded")
   recentlyReloaded = true
 end

-- These functions are global so they can be used from the REPL
function updatePackage(packageName,branch)
  local target = packageHome .. packageName
  -- Are we already there?
  if SILE.PackageManager.installed[packageName] == branch and branch ~= "HEAD" then
    print("Nothing to do!")
    return true
  end
  local cwd = lfs.currentdir()
  local r,e = lfs.chdir(target)
  if e then
    SU.warn("Package directory "..target.." went away! Trying again...")
    SILE.PackageManager.installed[packageName] = nil
    saveInstalled()
    installPackage(packageName)
  end

  local rv = os.execute("git pull")
  if not rv then
    SU.error("Error updating repository for package "..packageName..": "..rv)
  end
  local rv = os.execute("git checkout "..branch)
  if not rv then
    SU.error("Error updating repository for package "..packageName..": "..rv)
  end
  lfs.chdir(cwd)
  SILE.PackageManager.installed[packageName] = branch
  saveInstalled()
end

function installPackage(packageName)
  if not recentlyUpdated  then updateCatalogue() end
  if not recentlyReloaded then reloadCatalogue() end
  if not SILE.PackageManager.Catalogue[packageName] then
    -- Add support for URL-based package names later.
    SU.error("Can't install "..packageName..": package not known")
  end

  local metadata = SILE.PackageManager.Catalogue[packageName]

  -- Check dependencies
  if metadata.depends then
    for k,v in ipairs(metadata.depends) do
      if not SILE.PackageManager.installed[v] then
        print(packageName.." requires "..v..", installing that...")
        installPackage(v)
      end
    end
  end

  -- Clone repo in temp directory
  if metadata.repository then
    local branch = metadata.version or "HEAD"
    local target = packageHome .. packageName
    if lfs.attributes(target) then
      updatePackage(packageName, branch)
    else
      local rv = os.execute("git clone -c advice.detachedHead=false -b "..branch.." "..metadata.repository.." "..target)
      if not rv then -- This should return status code but it's returning true for me...
        SU.error("Error cloning repository for package "..packageName..": "..rv)
      end
    end
    SILE.PackageManager.installed[packageName] = branch
    saveInstalled()
  end
end

-- Set up the world
loadInstalledCatalogue()
fixupPaths()