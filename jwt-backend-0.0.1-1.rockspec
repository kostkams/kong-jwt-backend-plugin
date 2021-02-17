package = "jwt-backend"
version = "0.0.1-1"

supported_platforms = {"linux", "macosx"}
source = {
  url = "https://github.com/kostkams/kong-jwt-backend-plugin",
  tag = "1.0.0"
}

description = {
  summary = "kong-jwt-backend-plugin",
  homepage = "https://github.com/kostkams/kong-jwt-backend-plugin"
}

dependencies = {
}

local pluginName = "jwt-backend"

build = {
  type = "builtin",
  modules = {
    ["kong.plugins."..pluginName..".handler"] = "kong/plugins/"..pluginName.."/handler.lua",
    ["kong.plugins."..pluginName..".schema"] = "kong/plugins/"..pluginName.."/schema.lua",
    ["kong.plugins."..pluginName..".access"] = "kong/plugins/"..pluginName.."/access.lua"
  }
}