return {
  no_consumer = false, -- this plugin is available on APIs as well as on Consumers,
  fields = {
	-- 定义分流比例
	percentage = {type="number",required=true},
	-- 定义内测用户列表
	alphaUserList = { type = "array", default = {}},
	-- 如果命中分流规则后转发的upstream
	upstream = {type="string",required= true}
  },
  self_check = function(schema, plugin_t, dao, is_updating)
	-- check upstream
	local upstream =  plugin_t.upstream
	local percentage =  plugin_t.percentage
	if #upstream == 0 then
		return false
	end
	-- check percentage
	if percentage == nil or percentage>100 or percentage <0 then
		return false
	end

	return true
  end
}
