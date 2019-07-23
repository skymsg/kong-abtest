-- If you're not sure your plugin is executing, uncomment the line below and restart Kong
-- then it will throw an error which indicates the plugin is being loaded at least.

--assert(ngx.get_phase() == "timer", "The world is coming to an end!")


-- Grab pluginname from module name
local plugin_name = ({...})[1]:match("^kong%.plugins%.([^%.]+)")

-- load the base plugin object and create a subclass
local plugin = require("kong.plugins.base_plugin"):extend()
local crc32 = ngx.crc32_short

-- constructor
function plugin:new()
  plugin.super.new(self, plugin_name)

  -- do initialization here, runs in the 'init_by_lua_block', before worker processes are forked

end

---------------------------------------------------------------------------------------------
-- In the code below, just remove the opening brackets; `[[` to enable a specific handler
--
-- The handlers are based on the OpenResty handlers, see the OpenResty docs for details
-- on when exactly they are invoked and what limitations each handler has.
--
-- The call to `.super.xxx(self)` is a call to the base_plugin, which does nothing, except logging
-- that the specific handler was executed.
---------------------------------------------------------------------------------------------


--[[ handles more initialization, but AFTER the worker process has been forked/created.
-- It runs in the 'init_worker_by_lua_block'
function plugin:init_worker()
  plugin.super.init_worker(self)

  -- your custom code here

end --]]

--[[ runs in the ssl_certificate_by_lua_block handler
function plugin:certificate(plugin_conf)
  plugin.super.certificate(self)

  -- your custom code here

end --]]

--[[ runs in the 'rewrite_by_lua_block' (from version 0.10.2+)
-- IMPORTANT: during the `rewrite` phase neither the `api` nor the `consumer` will have
-- been identified, hence this handler will only be executed if the plugin is
-- configured as a global plugin!
function plugin:rewrite(plugin_conf)
  plugin.super.rewrite(self)

  -- your custom code here

end --]]

---[[ runs in the 'access_by_lua_block'
function plugin:access(plugin_conf)
  plugin.super.access(self)
  -- your custom code here
  local json_data = kong.request.get_body()
  local tmpId = json_data['tmpId']
  local alphaUserList = plugin_conf.alphaUserList
  local use_test_upstream = false
  if alphaUserList ~= nil and #alphaUserList>0 then
    for key,value in ipairs(alphaUserList)
    do
       kong.log.debug("alphaUserList "..key..":"..value)
       if value == tmpId  then
          use_test_upstream=true
       end
    end
  end
  -- 如果该用户不是内测用户,则根据用户id进行分流
  if not use_test_upstream then
    ngx.header["X-Kong-abtest-tmpId"] = tmpId
    local hash_value = crc32(tmpId)
    ngx.header["X-Kong-abtest-crc32"] = hash_value
    local bucket = hash_value % 100
    ngx.header["X-Kong-abtest-bucket"] = bucket
    if bucket <= plugin_conf.percentage then
      use_test_upstream = true
    end
  end
  if use_test_upstream then
    -- 设置upstream
    local ok,err = kong.service.set_upstream(plugin_conf.upstream)
    if not ok then
      kong.log.err(err)
      return
    end
    -- 匹配成功添加特定头部方便监控
    ngx.header["X-Kong-abtest-upstream"]=plugin_conf.upstream
  end
end --]]

---[[ runs in the 'header_filter_by_lua_block'
function plugin:header_filter(plugin_conf)
  plugin.super.header_filter(self)

  -- your custom code here, for example;
  -- ngx.header["Bye-World"] = "this is on the response"

end --]]

--[[ runs in the 'body_filter_by_lua_block'
function plugin:body_filter(plugin_conf)
  plugin.super.body_filter(self)

  -- your custom code here

end --]]

--[[ runs in the 'log_by_lua_block'
function plugin:log(plugin_conf)
  plugin.super.log(self)

  -- your custom code here

end --]]


-- set the plugin priority, which determines plugin execution order
plugin.PRIORITY = 1000

-- return our plugin object
return plugin
