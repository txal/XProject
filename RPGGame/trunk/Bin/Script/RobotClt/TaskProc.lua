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
	CmdNet.PBClt2Srv("GMCmdReq", oRobot:PacketID(), oRobot:GetSession(), {sCmd=sTask})
end

_tTaskProc["lreload"] = function(tParam, sTask)	--重载
	local bRes = gfReloadAll()
	LuaTrace("重载所有脚本 "..(bRes and "成功!" or "失败!"))
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

_tTaskProc["enterdup"] = function(tParam, sTask)
	local oRobot = goRobotMgr:RndRobot()
	if not oRobot then return end
	local nDupID = tonumber(tParam[1])
	CmdNet.PBClt2Srv("RoleEnterSceneReq", oRobot:PacketID(), oRobot:GetSession(), {nDupMixID=nDupID, nRoleID=oRobot:GetID()})
end
