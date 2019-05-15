--任务模块
local _tTaskProc = {}
function TaskDispatcher(sTask)
	local tParam = string.Split(sTask, " ")
	local sTaskName = tParam[1]
	table.remove(tParam, 1)

	local oFunc = _tTaskProc[sTaskName]
	if not oFunc then
		return LuaTrace("Task: '"..sTaskName.."' not define!")
	end
	oFunc(tParam, sTask)
end


-----------------处理函数------------------
local function _GMSendCmd(sTask)
	local oRobot = goRobotMgr:RndRobot()
	if not oRobot then return end
	oRobot:SendMsg("GMCmdReq", {sCmd=sTask})
end

_tTaskProc["lreload"] = function(tParam, sTask)	--重载
	local bRes = gfReloadAll("RobotClt")
	LuaTrace("重载所有脚本 "..(bRes and "成功!" or "失败!"))
end


_tTaskProc["auth"] = function(tParam, sTask)	--授权
	_GMSendCmd(sTask)
end

_tTaskProc["reload"] = function(tParam, sTask)	--重载
	_GMSendCmd(sTask)
end
_tTaskProc["svnupdate"] = function(tParam, sTask)	--重载
	_GMSendCmd(sTask)
end
_tTaskProc["reloadall"] = function(tParam, sTask)	--重载
	_GMSendCmd(sTask)
end

_tTaskProc["gitupdate"] = function(tParam, sTask)	--重载
	_GMSendCmd(sTask)
end

_tTaskProc["cgm"] = function(tParam, sTask)		--重载
	_GMSendCmd(sTask)
end

_tTaskProc["lgm"] = function(tParam, sTask)		--重载
	_GMSendCmd(sTask)
end

_tTaskProc["rgm"] = function(tParam, sTask)		--重载
	_GMSendCmd(sTask)
end

_tTaskProc["wgm"] = function(tParam, sTask)		--重载
	_GMSendCmd(sTask)
end

_tTaskProc["wgm2"] = function(tParam, sTask)		--重载
	_GMSendCmd(sTask)
end

_tTaskProc["agm"] = function(tParam, sTask)		--重载
	_GMSendCmd(sTask)
end

_tTaskProc["test"] = function(tParam, sTask)	--测试
	_GMSendCmd(sTask)
end

_tTaskProc["additem"] = function(tParam, sTask)
	_GMSendCmd(sTask)
end

_tTaskProc["dumpcmd"] = function (tParam, sTask)
	_GMSendCmd(sTask)
end

_tTaskProc["dumptable"] = function(tParam, sTask)
	_GMSendCmd(sTask)
end

_tTaskProc["clearbag"] = function(tParam, sTask)
	_GMSendCmd(sTask)
end


_tTaskProc["login"] = function(tParam, sTask)	--登录游戏
	if #tParam ~= 2 then
		return print("参数错误")
	end
	local sPrefix = tostring(tParam[1]) or ""
	local nRobotNum = tonumber(tParam[2]) or 1
	goRobotMgr:LoginRobot(sPrefix, nRobotNum)
end

_tTaskProc["logout"] = function(tParam, sTask)	--退出游戏
	goRobotMgr:LogoutRobot()
end

_tTaskProc["startrun"] = function(tParam, sTask)
	goRobotMgr:StartRun()
end
_tTaskProc["stoprun"] = function(tParam, sTask)
	goRobotMgr:StopRun()
end
_tTaskProc["startwalk"] = function(tParam, sTask)
	goRobotMgr:StartWalk()
end
_tTaskProc["stopwalk"] = function(tParam, sTask)
	goRobotMgr:StopWalk()
end

_tTaskProc["openact"] = function(tParam, sTask)
	_GMSendCmd(sTask)
end

_tTaskProc["close"] = function(tParam, sTask)
	NetworkExport.Terminate()
end

_tTaskProc["rolenum"] = function(tParam, sTask)
	LuaTrace("当前人数:", goRobotMgr.m_nRobotNum)
end

_tTaskProc["ping"] = function(tParam, sTask)
	local oRobot = goRobotMgr:RndRobot()
	if not oRobot then return end
    CmdNet.Clt2Srv("Ping", oRobot:PacketID(), oRobot:GetSession())
	gtPingMap[oRobot:GetSession()] = GF.GetClockMSTime()
end

_tTaskProc["mergeserver"] = function(tParam, sTask)
	local bTest = tParam[1] == "test"
	MergeDB(bTest)
end
