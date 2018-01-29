--Common script
require = gfRawRequire or require  --恢复原生require
require("Common/CommonInc")
require("Common/InitMysql")

--LogServer script
gfRawRequire = require 	--hook require
require = function(sScript)
	gfRawRequire("LogServer/"..sScript)
end
require("LogRpc")
require("MysqlPool")
require("GMMgr/GMMgrInc")

local function _InitGlobal()
	InitMysql()
	goMysqlPool:Init()
end

local nGCTime = 60
local function _LuaGC()
    collectgarbage()
end	

function Main()
	_InitGlobal()
    collectgarbage("setpause", 150)
    collectgarbage("setstepmul", 300)
    collectgarbage()
    goTimerMgr:Interval(nGCTime, function() _LuaGC() end)
	LuaTrace("LogServer lua start successful")
end

function Test()
end

