require("Config/Main")
require("Common/ItemDef")
require("Common/LuaClass")
require("Common/Extension/ExtensionInc")

local function fnError(sErr)
	local sGBKStr = utf8gbk(sErr, false)
	gfRawPrint(sGBKStr)
	local sGBKStr1 = utf8gbk(debug.traceback(), false)
	gfRawPrint(sGBKStr1)
end
xpcall(function() require("Common/ConfCheck/ConfCheckInc") end, fnError)