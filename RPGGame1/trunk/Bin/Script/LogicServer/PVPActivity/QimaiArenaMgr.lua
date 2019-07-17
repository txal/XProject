--七脉会武管理
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert


function CQimaiArenaMgr:Ctor(nActivityID)
	print("开始创建<七脉会武>活动管理器")
	CPVPActivityMgrBase.Ctor(self, nActivityID)
end

function CQimaiArenaMgr:OnActivityStart()
	print("<七脉会武>活动开始，开始创建活动实例")
	local nOpenTime = self:GetOpenTime()
	local nEndTime = self:GetEndTime()
	local nPrepareLastTime = self:GetPrepareLastTime()
	local tSceneConf = CPVPActivityMgr:GetActivitySceneConf(self:GetActivityID())
	local oInst = CQimaiArena:new(self, self:GetActivityID(), tSceneConf.nID, nOpenTime, nEndTime, nPrepareLastTime)
	table.insert(self.m_tInstMap, oInst)
	CPVPActivityMgrBase.OnActivityStart(self)
end

function CQimaiArenaMgr:GetInst()
	return self.m_tInstMap[1]  --本模块只有一个实例
end

--请注意，这里不能使用语法糖的self及活动实例相关数据，玩家分布在不同的逻辑服上，并不确保处于活动所在逻辑服
--fnCallback(bRet, sReason, nDupMixID)
function CQimaiArenaMgr:EnterCheck(oRole, nActivityID, fnCallback)
	local fnInnerCallback = function(bRet, sReason, nDupMixID) 
		if fnCallback then 
			fnCallback(bRet, sReason, nDupMixID)
		end
	end

	if not oRole:IsSysOpen(35) then 
		fnCallback(false, oRole.m_oSysOpen:SysOpenTips(35))
		return 
	end
	local tConf = ctPVPActivityConf[nActivityID]
	assert(tConf, "配置数据错误")
	--请注意，oRole对象所在的逻辑服可能和活动的目标逻辑服不在同一个逻辑服上
	local bTeam = tConf.bTeamPermit
	local nRoleTeamID = oRole:GetTeamID()
	if not bTeam then
		if nRoleTeamID > 0 then
			fnInnerCallback(false, "当前活动不允许组队进入，请先离队")
			return 
		end
	end

	if oRole:GetLevel() < tConf.nLimitLevel then
		local sReason = string.format("需等级达到%d级方可参与", tConf.nLimitLevel)
		fnInnerCallback(false, sReason)
		return
	end

	local nCurService = CUtil:GetServiceID()
	local nTarService = CPVPActivityMgr:GetActivityServiceID(nActivityID)
	if nCurService ~= nTarService then
		Network.oRemoteCall:CallWait("PVPActivityEnterCheckReq", fnInnerCallback, oRole:GetServer(), 
					nTarService, 0, nActivityID, oRole:GetID())
	else
		--调用本服的
		local bRet, sTipsCon, nSceneMixID = goPVPActivityMgr:EnterCheckReq(nActivityID, nRoleID)
		fnInnerCallback(bRet, sTipsCon, nSceneMixID)
	end
end

