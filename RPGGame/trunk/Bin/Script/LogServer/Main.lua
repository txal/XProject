cjson_raw.encode_sparse_array(true, 1, 1) --稀疏表转换成对象

--打开协议
local function OpenProto()
    local sDir = gsDataPath and gsDataPath or "../../"
    require(sDir.."/Data/Protobuf/LoadPBCProto")
    LoadProto(sDir.."/Data/Protobuf")
end


--Common script
require = gfRawRequire or require  --恢复原生require
require("Config/Main")
require("Common/CommonInc")
require("Common/InitMysql")
OpenProto()

--LogServer script
gfRawRequire = require 	--hook require
require = function(sScript)
	gfRawRequire("LogServer/"..sScript)
end
require("GMMgr/GMMgrInc")
require("LogMgr/LogMgrInc")
require("MysqlPool/MysqlPoolInc")
require("MainRpc")
require("ChatReport")

local function _InitGlobal()
	InitMysql()
	goMysqlPool:Init()
    goServerMgr:InitNew(gnServerID)
    goRemoteCall:Init()
    goChatReport:Init()
end

local function _UninitGlobal()
    local bSuccess = true
    local function fnError(sErr)
        bSuccess = false
        LuaTrace(sErr, debug.traceback())
    end

    xpcall(function() goRemoteCall:OnRelease() end, fnError)
    xpcall(function() goServerMgr:OnRelease() end, fnError)
    xpcall(function() goChatReport:OnRelease() end, fnError)
    xpcall(function() goLogMgr:OnRelease() end, fnError)
    return bSuccess
end

local nGCTime = 1800
local function _LuaGC()
    local nClock = os.clock() 
    collectgarbage()
    local sCostTime = string.format("%.4f", os.clock() - nClock)
    local nLuaMemery = math.floor((collectgarbage("count")/1024))
    LuaTrace("Lua memory: ", nLuaMemery, "M time:", sCostTime, " timers:", goTimerMgr:TimerCount())
end	

gnGCTimer = gnGCTimer
function Main()
	_InitGlobal()
    collectgarbage("setpause", 150)
    collectgarbage("setstepmul", 300)
    collectgarbage()
    gnGCTimer = goTimerMgr:Interval(nGCTime, function() _LuaGC() end)
    LuaTrace("启动 LogServer 完成******")
end

function Test()
end

function OnExitServer(nServer, nService)
    LuaTrace("服务器关闭------beg", nServer, nService)
    local bSuccess = _UninitGlobal()
    assert(bSuccess, "注意！！！关服报错了！！！")

    goTimerMgr:Clear(gnGCTimer)
    if goTimerMgr:TimerCount() > 0 then
        assert(false, "！！！计时器泄漏！！！剩余:"..goTimerMgr:TimerCount())
    end
    LuaTrace("服务器关闭------end")
end

