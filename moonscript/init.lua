module("moonscript", package.seeall)
local compile = require("moonscript.compile")
require("moonscript.parse")
local concat, insert = table.concat, table.insert
local split, dump
do
  local _table_0 = require("moonscript.util")
  split, dump = _table_0.split, _table_0.dump
end
local lua = {
  loadstring = loadstring
}
dirsep = "/"
line_tables = { }
local create_moonpath
create_moonpath = function(package_path)
  local paths = split(package_path, ";")
  for i, path in ipairs(paths) do
    local p = path:match("^(.-)%.lua$")
    if p then
      paths[i] = p .. ".moon"
    end
  end
  return concat(paths, ";")
end
to_lua = function(text, options)
  if options == nil then
    options = { }
  end
  if "string" ~= type(text) then
    local t = type(text)
    error("expecting string (got " .. t .. ")", 2)
  end
  local tree, err = parse.string(text)
  if not tree then
    error(err, 2)
  end
  local code, ltable, pos = compile.tree(tree, options)
  if not code then
    error(compile.format_error(ltable, pos, text), 2)
  end
  return code, ltable
end
moon_loader = function(name)
  local name_path = name:gsub("%.", dirsep)
  local file, file_path = nil, nil
  local _list_0 = split(package.moonpath, ";")
  for _index_0 = 1, #_list_0 do
    local path = _list_0[_index_0]
    file_path = path:gsub("?", name_path)
    file = io.open(file_path)
    if file then
      break
    end
  end
  if file then
    local text = file:read("*a")
    file:close()
    return loadstring(text, file_path)
  else
    return nil, "Could not find moon file"
  end
end
if not package.moonpath then
  package.moonpath = create_moonpath(package.path)
end
local init_loader
init_loader = function()
  return insert(package.loaders, 2, moon_loader)
end
if not _G.moon_no_loader then
  init_loader()
end
loadstring = function(str, chunk_name, options)
  if options == nil then
    options = nil
  end
  local passed, code, ltable = pcall(function()
    return to_lua(str, options)
  end)
  if not passed then
    error(chunk_name .. ": " .. code, 2)
  end
  if chunk_name then
    line_tables[chunk_name] = ltable
  end
  return lua.loadstring(code, chunk_name or "=(moonscript.loadstring)")
end
loadfile = function(fname, options)
  if options == nil then
    options = nil
  end
  local file, err = io.open(fname)
  if not file then
    return nil, err
  end
  local text = assert(file:read("*a"))
  file:close()
  return loadstring(text, fname, options)
end
dofile = function(fname, options)
  local f = assert(loadfile(fname))
  return f()
end
