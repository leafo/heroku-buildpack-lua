local rockspec_path, opt_dir = ...
if not opt_dir then
  error("Missing opt_dir")
end
if not rockspec_path then
  error("Missing rockspec_path")
end
local strip
strip = function(str)
  return str:match("^%s*(.-)%s*$")
end
local read_cmd
read_cmd = function(cmd)
  local f = io.popen(cmd, "r")
  do
    local _with_0 = strip(f:read("*a"))
    f:close()
    return _with_0
  end
end
local full_path
full_path = function(dir)
  local path = read_cmd("dirname " .. rockspec_path) .. "/" .. dir
  return read_cmd("cd " .. path .. " && pwd")
end
local tree = full_path("packages")
local bin = full_path("bin")
local luarocks_dir = opt_dir .. "/luarocks"
package.path = luarocks_dir .. "/?.lua;" .. package.path
local error
error = function(msg)
  print(msg)
  return os.exit(1)
end
local fn = loadfile(rockspec_path)
if not fn then
  error("Failed to open rockspec:", rockspec_path)
end
local rockspec = {
  name = "anonymous_app",
  dependencies = { }
}
setfenv(fn, rockspec)()
local path = require("luarocks.path")
local deps = require("luarocks.deps")
local install = require("luarocks.install")
local util = require("luarocks.util")
local cfg = require("luarocks.cfg")
cfg.wrap_bin_scripts = false
if rockspec.config then
  util.deep_merge(cfg, rockspec.config)
end
local extras = { }
do
  local _accum_0 = { }
  local _len_0 = 1
  local _list_0 = rockspec.dependencies
  for _index_0 = 1, #_list_0 do
    local dep = _list_0[_index_0]
    local parsed = deps.parse_dep(dep)
    if not parsed then
      table.insert(extras, dep)
    end
    local _value_0 = parsed
    _accum_0[_len_0] = _value_0
    _len_0 = _len_0 + 1
  end
  rockspec.dependencies = _accum_0
end
path.use_tree(tree)
cfg.deploy_bin_dir = bin
local success, msg = deps.fulfill_dependencies(rockspec, "one")
if not success then
  error(msg)
end
for _index_0 = 1, #extras do
  local extra = extras[_index_0]
  ok, err, exitcode = install.run(extra)
  if not ok then
    error(err)
  end
end
