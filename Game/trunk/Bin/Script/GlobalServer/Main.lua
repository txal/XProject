math.randomseed(os.clock()*1000)
math.random() math.random() math.random()
cjson.encode_sparse_array(true, 1, 1) --稀疏表转换成对象

--Common script
require = gfRawRequire or require  --恢复原生require
require("Config/Main")
require("Common/CommonInc")

--GlobalServer script
gfRawRequire = require 	--hook require
require = function(sScript)
	gfRawRequire("GlobalServer/"..sScript)
end
require("GMCmd/GMCmdRpc")
require("Global/GlobalInc")
require("Browser/BrowserInc")
require("GPlayer/GPlayerInc")
require("Recharge/RechargeInc")
require("RoomMatch/RoomMatchInc")


local nGCTime = 1000*60
local function _LuaGC()
    collectgarbage()
end	

function Main()
    collectgarbage("setpause", 150)
    collectgarbage("setstepmul", 300)
    collectgarbage()
	GlobalExport.RegisterTimer(nGCTime, function() _LuaGC() end)
	LuaTrace("GlobalServer lua start successful")
end

function Test()
end
