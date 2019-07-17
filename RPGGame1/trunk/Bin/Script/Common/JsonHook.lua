--替换cjson的encode和decode
local function _fnHookJson()
	if not cjson then
		return
	end
	assert(cseri, "cseri不存在")
	cjson.oencode = cjson.oencode or cjson.encode --重载要这样处理
	cjson.odecode = cjson.odecode or cjson.decode

	cjson.encode = function(t)
		assert(type(t)=="table", "参数必须是表")
		return cseri.encode(t)
	end
	cjson.decode = function(d)
		assert(type(d)=="string", "参数必须是字符串")
		if d == "" then
			return {}
		end
		return cseri.decode(d)
	end
end
_fnHookJson()
