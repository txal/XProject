math.randomseed(os.clock()*1000)
math.random() math.random() math.random()
cjson.encode_sparse_array(true, 1, 1) --稀疏表转换成对象

--Global script
require = gfRawRequire or require  --恢复原生require
require("Config/Main")
require("Common/CommonInc")
--require("../../Data/Protobuf/LoadPBCProto")
--LoadProto()

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
	local oSSDB = SSDBDriver:new()
	oSSDB:Connect("127.0.0.1", 10001)
	print(oSSDB:HIncr("CharIDDB", "IDIncr"))
end
