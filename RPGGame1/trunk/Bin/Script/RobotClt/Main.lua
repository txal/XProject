math.randomseed(os.clock()*1000)
math.random() math.random() math.random()
cjson.encode_sparse_array(true, 1, 1) --稀疏表转换成对象

--打开协议
local function OpenProto()
    local sDir = gsDataPath and gsDataPath or "../../"
    require(sDir.."/Data/Protobuf/LoadPBCProto")
    LoadProto(sDir.."/Data/Protobuf")
end

--Global script
require = gfRawRequire or require  --恢复原生require
require("RobotConf")
require("Config/Main")
require("Common/CommonInc")
CHDBase = CHDBase or class()
require("GlobalServer/HDMgr/HDBase")
require("GlobalServer/HDMgr/HDDef")
require("GlobalServer/SystemMall/SystemMallDef")
require("GlobalServer/RankingMgr/RankingDef")
require("GlobalServer/RankingMgr/RankingDef")
require("LogicServer/Module/ModuleDef")
require("MergeServer/MergeServer")
OpenProto()

--RobotClt
gfRawRequire = require 	--hook require
require = function(sScript)
	gfRawRequire("RobotClt/"..sScript)
end
require("TaskProc")
require("Robot/RobotInc")


function Main()
	bServer = false
    print("启动机器人成功")
    Test()
end

function Test()
end

