math.randomseed(os.clock()*1000)
math.random() math.random() math.random()
cjson.encode_sparse_array(true, 1, 1) --稀疏表转换成对象

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

--Global script
require = gfRawRequire or require  --恢复原生require
require("Config/Main")
-- require("ServerConf")
require("Common/CommonInc")
OpenProto()

--RobotClt
gfRawRequire = require 	--hook require
require = function(sScript)
	gfRawRequire("RobotClt/"..sScript)
end
require("TaskProc")
require("RobotConf")
require("Robot/RobotInc")

--连接数据库
-- goDBMgr = goDBMgr or CDBMgr:new()
-- goDBMgr:Init()

function Main()
	CmdNet.bServer = false
    print("启动机器人成功")
    Test()
end

function Test()
    local function _compare(v1, v2)
        if v1 > v2 then
            return 1
        end
        if v1 < v2 then
            return -1 
        end
        return 0
    end
    local oMinHeap = CMinHeap:new(_compare)
    local beg = os.clock()
    for k = 1, 100000 do
        oMinHeap:Push(k)
    end
    print("time push:", os.clock() - beg, oMinHeap:GetCount())

    beg = 0
    for k = 1, 100000 do
        oMinHeap:RemoveByValue(k)
    end
    print("time remove:", os.clock() - beg, oMinHeap:GetCount())
end

