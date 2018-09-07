--Common script
require = gfRawRequire or require  --恢复原生require
require("Common/CommonInc")

--LogServer script
gfRawRequire = require 	--hook require
require = function(sScript)
	gfRawRequire("LogServer/"..sScript)
end
require("InitMysql")
require("MysqlPool")
require("LogRpc")

local nGCTime = 1000*60
local function _LuaGC()
    collectgarbage()
end	

local function _InitGlobal()
	goMysqlPool:Init()
end

function Main()
	_InitGlobal()
    collectgarbage("setpause", 150)
    collectgarbage("setstepmul", 300)
    collectgarbage()
	GlobalExport.RegisterTimer(nGCTime, function() _LuaGC() end)
	LuaTrace("LogServer lua start successful")
	Test()
end

function Test()
end

