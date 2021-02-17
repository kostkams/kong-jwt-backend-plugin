local ltn12 = require("ltn12")
local http = require "socket.http"
local json = require "lunajson"

local kong = kong
local type = type
local re_gmatch = ngx.re.gmatch

local _M = {}

local function retrieve_token(conf)
    local request_headers = kong.request.get_headers()
    for _, v in ipairs(conf.header_names) do
        local token_header = request_headers[v]
        if token_header then
            if type(token_header) == "table" then
                token_header = token_header[1]
            end
            local iterator, iter_err = re_gmatch(token_header, "\\s*[Bb]earer\\s+(.+)")
            if not iterator then
                kong.log.err(iter_err)
                break
            end

            local m, err = iterator()
            if err then
                kong.log.err(err)
                break
            end

            if m and #m > 0 then
                return m[1]
            end
        end
    end
end

local function call_validate(conf, token)
    local url

    if conf.kubernetes_external_name then
        url = "http://"
                .. conf.kubernetes_external_name
                .. conf.api_validate_url
    else
        url = kong.request.get_scheme()
                .. "://" .. kong.request.get_host()
                .. ":" .. kong.request.get_port()
                .. conf.api_path_prefix
                .. conf.api_validate_url
    end

    local t = {}
    local ok, statusCode = http.request {
        url = url,
        sink = ltn12.sink.table(t),
        method = "GET",
        headers = {
            Authorization = "Bearer " .. token
        }
    }

    return statusCode == 200
end

local function get_user_infos(conf, token)
    local url

    if conf.kubernetes_external_name then
        url = "http://"
                .. conf.kubernetes_external_name
                .. conf.api_user_url
    else
        url = kong.request.get_scheme()
                .. "://" .. kong.request.get_host()
                .. ":" .. kong.request.get_port()
                .. conf.api_path_prefix
                .. conf.api_user_url
    end


    local t = {}
    local ok, statusCode = http.request {
        url = url,
        sink = ltn12.sink.table(t),
        method = "GET",
        headers = {
            Authorization = "Bearer " .. token
        }
    }

    local body = table.concat(t)
    if statusCode == 200 then
        return true, body
    end
    return false, nil;
end

local function check_jwt(conf)
    local token, err = retrieve_token(conf)

    if err then
        kong.log.err(err)
        return kong.response.exit(500, { message = "An unexpected error occurred" })
    end

    local token_type = type(token)
    if token_type ~= "string" then
        if token_type == "nil" then
            return false, { status = 401, message = "Unauthorized" }, nil
        elseif token_type == "table" then
            return false, { status = 401, message = "Multiple tokens provided" }, nil
        else
            return false, { status = 401, message = "Unrecognizable token" }, nil
        end
    end

    local ok = call_validate(conf, token)
    if not ok then
        return false, { status = 401, message = "Unauthorized" }, nil
    end

    local ok1, user = get_user_infos(conf, token)
    if not ok1 then
        return false, { status = 401, message = "Unauthorized" }, nil
    end

    return true, nil, user
end

local function set_user(user)
    local set_header = kong.service.request.set_header
    set_header('x-user', user)
end

local function ends_with(str, ending)
    return ending == "" or str:sub(-#ending) == ending
end

local function starts_with(str, start)
    return str:sub(1, #start) == start
end

local function is_empty(s)
    return s == nil or s == ''
end

function _M.execute(conf)
    -- check if preflight request and whether it should be authenticated
    if not conf.run_on_preflight and kong.request.get_method() == "OPTIONS" then
        return
    end

    if ends_with(kong.request.get_path(), conf.api_login_url)
            or ends_with(kong.request.get_path(), conf.api_validate_url)
            or ends_with(kong.request.get_path(), conf.api_user_url)
            or not starts_with(kong.request.get_path(), '/api') then
        return
    end

    local ok, err, user = check_jwt(conf)

    if ok then
        set_user(user)
    else
        return kong.response.exit(err.status, err.erros or { message = err.message })
    end
end

return _M