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
OpenProto()

--GlobalServer script
gfRawRequire = require 	--hook require
require = function(sScript)
	gfRawRequire("GlobalServer/"..sScript)
end
require("MainRpc")
-- require("GMMgr/GMMgrInc")
-- require("HDMgr/HDMgrInc")
-- require("Browser/BrowserInc")
-- require("NoticeMgr/NoticeMgrInc")
-- require("HDCircle/HDCircleInc")
-- require("Recharge/RechargeInc")
-- require("MailMgr/MailMgrInc")
-- require("KeyExchange/KeyExchangeInc")
-- require("RankingMgr/RankingMgrInc")
-- require("SystemMall/SystemMallInc")
-- require("Market/MarketInc")
-- require("Union/UnionInc")
-- require("Arena/ArenaInc")
-- require("HallFame/HallFameInc")
-- require("YaoShouTuXiMgr/YaoShouTuXiMgrInc")
-- require("ExchangeActivity/ExchangeActivityMgrInc")
-- require("GuaJiTimerMgr/GuaJiTimerMgrInc")

--全局初始化
local function _InitGlobal()
    Network:Init()
    local tGModuleList = {}
    local nServiceID = CUtil:GetServiceID()
    for _, tModule in pairs(gtGModuleDef) do
        if table.InArray(nServiceID, tModule.tServiceID) then
            table.insert(tGModuleList, tModule.cClass:new())
        end
    end
    goGModuleMgr:Init(tGModuleList)
end

--全局反初始化
local function _UninitGlobal()
    local bSuccess = true
    local function fnError(sErr)
        bSuccess = false
        LuaTrace(sErr, debug.traceback())
    end

    xpcall(function() Network:Release() end, fnError)
    xpcall(function() goGModuleMgr:Release() end, fnError)
    return bSuccess
end

--GC
local nGCIndex = 0
local nGCTime = 10
gnGCTimer = gnGCTimer
local function _fnLuaGC()
    local nClock = os.clock() 
    if nGCIndex % 180 == 0 then
        collectgarbage()
    else
        collectgarbage("step", 1024) --kb
    end
    if nGCIndex % 30 == 0 then --5分钟打印1次
        local sCostTime = string.format("%.4f", os.clock() - nClock)
        local nLuaMemery = math.floor((collectgarbage("count")/1024))
        local sGCLog = string.format("LUA MEM:%dM time:%s index:%d timers:%d", nLuaMemery, sCostTime, nGCIndex, GetGModule("TimerMgr"):TimerCount())
        LuaTrace(sGCLog)
    end
    nGCIndex = nGCIndex + 1
end

function Main()
    _InitGlobal()
    collectgarbage()
    collectgarbage("setpause", 100)
    collectgarbage("setstepmul", 300)
    gnGCTimer = GetGModule("TimerMgr"):Interval(nGCTime, function() _fnLuaGC() end)
    local nLuaMemory = math.floor((collectgarbage("count")/1024))
    LuaTrace("启动 GlobalServer 完成******", "LUA MEM:", nLuaMemory)
end

--执行关服
function OnServerClose(nServerID)
    LuaTrace("服务器关闭------beg", nServerID)
    gbServerClosing = true
    goGModuleMgr:OnServerClose(nServerID)

    --可能是跨服服务,所有要判断下
    if GetGModule("ServerMgr"):GetServerID() == nServerID then
        local bSuccess = _UninitGlobal()
        assert(bSuccess, "关服报错了！")

        --计时器检测
        local oTimerMgr = GetGModule("TimerMgr")
        oTimerMgr:Clear(gnGCTimer)
        if oTimerMgr:TimerCount() > 0 then
            oTimerMgr:DebugLog()
            assert(false, "计时器泄漏！剩余:"..oTimerMgr:TimerCount())
        end
    end
    LuaTrace("服务器关闭------end", nServerID)
end
