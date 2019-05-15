math.randomseed(os.clock()*1000)
math.random() math.random() math.random()
cjson.encode_sparse_array(true, 1, 1) --稀疏表转换成对象
cjson_raw.encode_sparse_array(true, 1, 1) --稀疏表转换成对象

--打开协议
local function OpenProto()
    local sDir = gsDataPath and gsDataPath or "../../"
    require(sDir.."/Data/Protobuf/LoadPBCProto")
    LoadProto(sDir.."/Data/Protobuf")
end

--Common script
require = gfRawRequire or require  --恢复原生require
require("ServerConf")
require("Config/Main")
require("Common/CommonInc")
require("Common/GPlayer/GPlayerInc")
OpenProto()

--GlobalServer script
gfRawRequire = require 	--hook require
require = function(sScript)
	gfRawRequire("WGlobalServer2/"..sScript)
end

require("MainRpc")
require("GMMgr/GMMgrInc")
require("House/HouseInc")
require("ItemQuery/ItemQueryInc")
require("Misc/MiscInc")
require("HDBook/HDBookInc")

--全局初始化
local function _InitGlobal()
    goDBMgr:InitNew()
    goServerMgr:InitNew(gnServerID)
    
    goRemoteCall:Init()
    goClientCall:Init(GF.GetServiceID())

    goGPlayerMgr:LoadData()
    goHouseMgr:Init()
    goItemQueryMgr:Init()
    goHDBook:LoadData()
end

--全局反初始化
local function _UninitGlobal()
    local bSuccess = true
    local function fnError(sErr)
        bSuccess = false
        LuaTrace(sErr, debug.traceback())
    end

    xpcall(function() goDBMgr:OnRelease() end, fnError)
    xpcall(function() goRemoteCall:OnRelease() end, fnError)
    xpcall(function() goClientCall:OnRelease() end, fnError)
    xpcall(function() goServerMgr:OnRelease() end, fnError)

    xpcall(function() goGPlayerMgr:OnRelease() end, fnError)
    xpcall(function() goHouseMgr:OnRelease() end, fnError)
    xpcall(function() goItemQueryMgr:OnRelease() end, fnError)
    xpcall(function() goHDBook:OnRelease() end, fnError)
    return bSuccess
end


--GC
local nGCIndex = 0
local nGCTime = 10
local function _LuaGC()
    local nClock = os.clock() 
    if nGCIndex % 18 == 0 then
        collectgarbage()
    else
        collectgarbage("step", 1024) --k
    end
    if nGCIndex % 30 == 0 then --5分钟打印1次
        local sCostTime = string.format("%.4f", os.clock() - nClock)
        local nLuaMemery = math.floor((collectgarbage("count")/1024))
        LuaTrace("Lua memory: ", nLuaMemery, "M time:", sCostTime, " index:", nGCIndex, " timers:", goTimerMgr:TimerCount(), goGPlayerMgr:GetCount())
    end
    nGCIndex = nGCIndex + 1
end

gnGCTimer = gnGCTimer
function Main()
    _InitGlobal()
    collectgarbage("setpause", 100)
    collectgarbage("setstepmul", 300)
    collectgarbage()
    gnGCTimer = goTimerMgr:Interval(nGCTime, function() _LuaGC() end)
	LuaTrace("启动 WGlobalServer2 成功")
end

function OnExitServer(nServer, nService)
    LuaTrace("服务器关闭------beg", nServer, nService)
    gbServerClosing = true

    local bSuccess = _UninitGlobal()
    assert(bSuccess, "注意！！！关服报错了！！！")

    goTimerMgr:Clear(gnGCTimer)
    if goTimerMgr:TimerCount() > 0 then
        goTimerMgr:DebugLog()
        assert(false, "！！！计时器泄漏！！！剩余:"..goTimerMgr:TimerCount())
    end
    LuaTrace("服务器关闭------end")

end

print("WGlobalServer2##########reload")