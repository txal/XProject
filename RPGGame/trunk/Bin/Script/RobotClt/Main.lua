math.randomseed(os.clock()*1000)
math.random() math.random() math.random()
cjson.encode_sparse_array(true, 1, 1) --稀疏表转换成对象

--打开协议
local function OpenProto()
    local f = io.open("protopath.txt", "r")
    if not f then
        require("../../Data/Protobuf/LoadPBCProto")
        LoadProto("../../Data/Protobuf")
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


function Main()
	CmdNet.bServer = false
    print("启动机器人成功")
    Test()
end

function Test()
end

