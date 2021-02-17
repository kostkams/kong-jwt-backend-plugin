local BasePlugin = require "kong.plugins.base_plugin"
local access = require "kong.plugins.jwt-backend.access"


local JwtBackendHandler = BasePlugin:extend()

JwtBackendHandler.PRIORITY = 1006
JwtBackendHandler.VERSION  = "0.0.1"

function JwtBackendHandler:new()
  JwtBackendHandler.super.new(self, "jwt-backend")
end

function JwtBackendHandler:access(conf) 
    access.execute(conf)
end

return JwtBackendHandler