math.randomseed(os.clock()*1000)
math.random() math.random() math.random()
cjson.encode_sparse_array(true, 1, 1) --稀疏表转换成对象
cjson_raw.encode_sparse_array(true, 1, 1) --稀疏表转换成对象

--打开协议
local function OpenProto()
    local f = io.open("protopath.txt", "r")
    if not f then
        require("../../Data/Protobuf/LoadPBCProto")
        LoadProto("../Data/Protobuf")
        return
    else
        local sLoaderPath = f:read("l")
        local sProtoPath = f:read("l")
        f:close()
        require(sLoaderPath)
        LoadProto(sProtoPath)
        return
    end
end

--Common script
require = gfRawRequire or require  --恢复原生require
require("Config/Main")
require("Common/CommonInc")
require("ServerConf")
OpenProto()

--GlobalServer script
gfRawRequire = require 	--hook require
require = function(sScript)
	gfRawRequire("GlobalServer/"..sScript)
end
require("Browser/BrowserInc")
require("GMMgr/GMMgrInc")
require("Global/GlobalInc")
require("Notice/NoticeInc")
require("GPlayer/GPlayerInc")
require("Recharge/RechargeInc")
require("GiftExchange/GiftExchangeInc")
require("MailTask/MailTaskInc")
require("HDCircle/HDCircleInc")

--连接数据库
goDBMgr = goDBMgr or CDBMgr:new()
goDBMgr:Init()

--全局初始化
local function _InitGlobal()
    goNoticeMgr:LoadData()
    goMailTask:LoadData()
    goHDCircle:LoadData()

end

--全局反初始化
local function _UninitGlobal()
    xpcall(function() goRecharge:OnRelease() end, function(sErr) LuaTrace(sErr) end)
    xpcall(function() goNoticeMgr:OnRelease() end, function(sErr) LuaTrace(sErr) end)
    xpcall(function() goMailTask:OnRelease() end, function(sErr) LuaTrace(sErr) end)
    xpcall(function() goHDCircle:OnRelease() end, function(sErr) LuaTrace(sErr) end)
    
end


local nGCTime = 60 --秒
local function _LuaGC()
    collectgarbage()
end	

gnGCTimer = gnGCTimer
function Main()
    _InitGlobal()
    collectgarbage("setpause", 100)
    collectgarbage("setstepmul", 300)
    collectgarbage()
    gnGCTimer = goTimerMgr:Interval(nGCTime, function() _LuaGC() end)
	LuaTrace("GlobalServer lua start successful")
end

function OnExitServer()
    LuaTrace("OnExitServer***")
    _UninitGlobal()
	os.exit()
end
