local _tTaskProc = {}
function TaskDispatcher(sTask)
	local tParam = string.Split(sTask, " ")
	local sTaskName = tParam[1]
	table.remove(tParam, 1)
	if not _tTaskProc[sTaskName] then
		return LuaTrace("Task: '"..sTaskName.."' not define!")
	end
	_tTaskProc[sTaskName](tParam, sTask)
end


-----------------处理函数------------------
_tTaskProc["auth"] = function(tParam, sTask)	--授权
	local oRobot = goRobotMgr:GetRndRobot()
	if not oRobot then return end
	CmdNet.PBClt2Srv(oRobot:GenPacketIdx(), oRobot:GetSession(), "GMCmdReq", {sCmd=sTask})
end

_tTaskProc["login"] = function(tParam, sTask)	--登录游戏
	local nMinRobotID = tonumber(tParam[1]) or 0
	local nMaxRobotID = tonumber(tParam[2]) or 0
	if nMinRobotID <= 0 or nMaxRobotID < nMaxRobotID then
		return LuaTrace("like: login 1 100")
	end
	goRobotMgr:LoginRobot(nMinRobotID, nMaxRobotID)
end

_tTaskProc["loginaccount"] = function(tParam, sTask)--登录账号
	local sAccount = tostring(tParam[1]) or ""
	if sAccount == "" then
		return LuaTrace("like: loginaccount name")
	end
	goRobotMgr:LoginAccount(sAccount)
end

_tTaskProc["logout"] = function(tParam, sTask)	--退出游戏
	goRobotMgr:LogoutRobot()
end

_tTaskProc["reload"] = function(tParam, sTask)	--重载
	local oRobot = goRobotMgr:GetRndConn()
	if not oRobot then return end
	CmdNet.PBClt2Srv(oRobot:GenPacketIdx(), oRobot:GetSession(), "GMCmdReq", {sCmd=sTask})
end

_tTaskProc["lgm"] = function(tParam, sTask)		--重载
	local oRobot = goRobotMgr:GetRndConn()
	if not oRobot then return end
	CmdNet.PBClt2Srv(oRobot:GenPacketIdx(), oRobot:GetSession(), "GMCmdReq", {sCmd=sTask})
end

_tTaskProc["test"] = function(tParam, sTask)	--测试
	local oRobot = goRobotMgr:GetRndRobot()
	if not oRobot then return end
	CmdNet.PBClt2Srv(oRobot:GenPacketIdx(), oRobot:GetSession(), "GMCmdReq", {sCmd=sTask})
end

_tTaskProc["client"] = function(tParam, sTask)	
	local oRobot = goRobotMgr:GetRndRobot()
	if not oRobot then return end
	local nPosX, nPosY = oRobot:GetPos()
	CmdNet.Clt2Srv(oRobot:GenPacketIdx(), oRobot:GetSession(), "Attack", nPosX, nPosY, 65535, 255, 1.1, os.time())
	-- CmdNet.Clt2Srv(oRobot:GenPacketIdx(), oRobot:GetSession(), "ActorHurted", 111, 255, nPosX, nPosY, 1000, 1000)
	-- CmdNet.Clt2Srv(oRobot:GenPacketIdx(), oRobot:GetSession(), "ActorDamage", 222, 1, nPosX, nPosY, 1111, 111)
end

_tTaskProc["startrun"] = function(tParam, sTask)
	goRobotMgr:StartRun()
end

_tTaskProc["addgold"] = function(tParam, sTask)
	local oRobot = goRobotMgr:GetRndRobot()
	if not oRobot then return end
	CmdNet.PBClt2Srv(oRobot:GenPacketIdx(), oRobot:GetSession(), "GMCmdReq", {sCmd=sTask})
end

_tTaskProc["addmoney"] = function(tParam, sTask)
	local oRobot = goRobotMgr:GetRndRobot()
	if not oRobot then return end
	CmdNet.PBClt2Srv(oRobot:GenPacketIdx(), oRobot:GetSession(), "GMCmdReq", {sCmd=sTask})
end

_tTaskProc["dumpcmd"] = function (tParam, sTask)
	local oRobot = goRobotMgr:GetRndRobot()
	if not oRobot then return end
	CmdNet.PBClt2Srv(oRobot:GenPacketIdx(), oRobot:GetSession(), "GMCmdReq", {sCmd=sTask})
end

_tTaskProc["dumptable"] = function(tParam, sTask)
	local oRobot = goRobotMgr:GetRndRobot()
	if not oRobot then return end
	CmdNet.PBClt2Srv(oRobot:GenPacketIdx(), oRobot:GetSession(), "GMCmdReq", {sCmd=sTask})
end

_tTaskProc["sceneready"] = function(tParam)
	goRobotMgr:SceneReady()	
end

_tTaskProc["openbag"] = function(tParam, sTask)
	local oRobot = goRobotMgr:GetRndRobot()
	if not oRobot then return end
	CmdNet.PBClt2Srv(oRobot:GenPacketIdx(), oRobot:GetSession(), "GMCmdReq", {sCmd=sTask})
end

_tTaskProc["clearbag"] = function(tParam, sTask)
	local oRobot = goRobotMgr:GetRndRobot()
	if not oRobot then return end
	CmdNet.PBClt2Srv(oRobot:GenPacketIdx(), oRobot:GetSession(), "GMCmdReq", {sCmd=sTask})
end

_tTaskProc["additem"] = function(tParam, sTask)
	local oRobot = goRobotMgr:GetRndRobot()
	if not oRobot then return end
	CmdNet.PBClt2Srv(oRobot:GenPacketIdx(), oRobot:GetSession(), "GMCmdReq", {sCmd=sTask})
end

_tTaskProc["inittask"] = function(tParam, sTask)
	local oRobot = goRobotMgr:GetRndRobot()
	if not oRobot then return end
	CmdNet.PBClt2Srv(oRobot:GenPacketIdx(), oRobot:GetSession(), "GMCmdReq", {sCmd=sTask})
end
