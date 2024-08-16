--
-- Licensed to the Apache Software Foundation (ASF) under one or more
-- contributor license agreements.  See the NOTICE file distributed with
-- this work for additional information regarding copyright ownership.
-- The ASF licenses this file to You under the Apache License, Version 2.0
-- (the "License"); you may not use this file except in compliance with
-- the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--

-- https://casdoor.org/docs/basic/public-api

local core      = require("apisix.core")
local http      = require("resty.http")

local norm_path = require("pl.path").normpath

local ngx_re    = require("ngx.re")
local env       = core.env


local schema = {
    type = "object",
    properties = {
        uri = core.schema.uri_def,
        prefix = {
            type = "string",
        },
        token = {
            type = "string",
        },
    },
    required = { "uri", "prefix", "token" },
}

local _M = {
    schema = schema
}

local function make_request_to_casdoor(conf, method, path, query, data)
    local httpc = http.new()
    -- config timeout or default to 5000 ms
    httpc:set_timeout((conf.timeout or 5) * 1000)

    local req_addr = conf.uri .. norm_path(path)
    core.log.info("make_request_to_casdoor req_addr: ", req_addr)

    local token, _ = env.fetch_by_uri(conf.token)
    if not token then
        token = conf.token
    end

    local headers = {
        ["Authorization"] = token
    }

    local res, err = httpc:request_uri(req_addr, {
        method = method,
        headers = headers,
        body = core.json.encode(data or {}, true),
        query = query or nil,
    })

    if not res then
        return nil, err
    end

    core.log.info("res.body: ", core.json.delay_encode(res.body))

    return res.body
end

---@param user_id string
---@return table|nil res.data, string|nil err the user
local function get_user(conf, user_id)
    core.log.info("get_user userId: ", user_id)
    local res_body, err = make_request_to_casdoor(conf, "GET", "/api/get-user", { userId = user_id }, nil)
    if not res_body then
        return nil, "failed to retrtive data from casdoor user: " .. err
    end
    local res = core.json.decode(res_body)
    if not res or not res.data then
        return nil, "failed to decode result, res: " .. res_body
    end

    return res.data, nil
end

-- key is the casdoor path
local function get(conf, key)
    core.log.info("fetching data from casdoor for key: ", key)

    local key_path = ngx_re.split(key, "/")

    if not key_path or #key_path < 1 then
        return nil, "error key format, key: " .. key
    end

    local user, err
    if conf.prefix == "user" then
        user, err = get_user(conf, key_path[1])
        if err then
            return nil, err
        end
        assert(user)

        local ret = user
        for i = 2, #key_path, 1 do
            local child_key = key_path[i]
            if not ret[child_key] then
                core.log.info("child_key '" .. child_key .. "' not found: ")
                return nil
            end
            ret = ret[child_key]
        end
        return ret
    else
        return nil
    end

    return nil
end

_M.get = get


return _M
