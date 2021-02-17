local typedefs = require "kong.db.schema.typedefs"

return {
  name = "jwt-backend",
  fields = {
    { consumer = typedefs.no_consumer },
    { protocols = typedefs.protocols_http },
    { config = {
        type = "record",
        fields = {
          { api_validate_url = {  type = "string", default = "/authentication/validate", required = true, } },
          { api_path_prefix = { type = "string", default = "/api/user-management", required = true, } },
          { api_login_url = { type = "string", default = "/authentication/login", required = true, } },
          { api_user_url = { type = "string", default = "/authentication/user", required = true, } },
          { kubernetes_external_name = { type = "string", required = true, }, },
          { run_on_preflight = { type = "boolean", default = true, }, },
          { header_names = { type = "set", elements = { type = "string" }, default = { "authorization" }, required = true, }, },
        },
      }, },
  }
}