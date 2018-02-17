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
	CmdNet.PBClt2Srv("GMCmdReq", oRobot:GenPacketIdx(), oRobot:GetSession(), {sCmd=sTask})
end
_tTaskProc["auth"] = function(tParam, sTask)	--授权
	_GMSendCmd(sTask)
end

_tTaskProc["reload"] = function(tParam, sTask)	--重载
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
	local sPrefix = tParam[1] or ""
	local nRobotNum = tonumber(tParam[2]) or 100
	goRobotMgr:LoginRobot(sPrefix, nRobotNum)
end

_tTaskProc["logout"] = function(tParam, sTask)	--退出游戏
	goRobotMgr:LogoutRobot()
end

_tTaskProc["startrun"] = function(tParam, sTask)
	goRobotMgr:StartRun()
end

_tTaskProc["sceneready"] = function(tParam)
	goRobotMgr:SceneReady()	
end
