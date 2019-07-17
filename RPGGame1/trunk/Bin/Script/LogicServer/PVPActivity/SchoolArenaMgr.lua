--首席争霸管理
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert


function CSchoolArenaMgr:Ctor(nActivityID)
	print("开始创建<首席争霸>活动管理器")
	CPVPActivityMgrBase.Ctor(self, nActivityID)
	--self.m_tInstMap = {}   --活动实例map {SchoolID:ActivityInst} --基类有
end

function CSchoolArenaMgr:OnActivityStart()
	print("<首席争霸>活动开始，开始创建实例")
	local nOpenTime = self:GetOpenTime()
	local nEndTime = self:GetEndTime()
	local nPrepareLastTime = self:GetPrepareLastTime()
	for k, tConf in pairs(ctRoleInitConf) do  --迭代这张表
		assert(tConf.nSchool > 0, "配置错误")
		local nSchool = tConf.nSchool
		local nActivityID = self:GetActivityID()
		if not self.m_tInstMap[nSchool] then
			local tSceneConf = CPVPActivityMgr:GetActivitySceneConf(nActivityID, nSchool)
			self.m_tInstMap[nSchool] = CSchoolArena:new(self, nActivityID, tSceneConf.nID, nSchool, nOpenTime, nEndTime, nPrepareLastTime)
		end
	end
	CPVPActivityMgrBase.OnActivityStart(self)
end

function CSchoolArenaMgr:GetActivityInst(nSchool)
	return self.m_tInstMap[nSchool]
end

function CSchoolArenaMgr:GetInst(nSchoolID)
	assert(nSchoolID and nSchoolID > 0, "参数错误")
	return self:GetActivityInst(nSchoolID)
end

--请注意，这里不能使用语法糖的self及活动实例相关数据，玩家分布在不同的逻辑服上，并不确保处于活动所在逻辑服
--fnCallback(bRet, sReason, nDupMixID)
function CSchoolArenaMgr:EnterCheck(oRole, nActivityID, fnCallback)
	local fnInnerCallback = function(bRet, sReason, nDupMixID) 
		if fnCallback then 
			fnCallback(bRet, sReason, nDupMixID)
		end
	end

	if not oRole or nActivityID <= 0 then 
		fnInnerCallback(false)
		return 
	end
	local tConf = ctPVPActivityConf[nActivityID]
	if not tConf then 
		return fnInnerCallback(false)
	end
	if not oRole:IsSysOpen(33) then
		fnInnerCallback(false, oRole.m_oSysOpen:SysOpenTips(33))
		return 
	end

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
					nTarService, 0, nActivityID, oRole:GetID(), oRole:GetSchool())
	else
		--调用本服的
		local bRet, sTipsCon, nSceneMixID = goPVPActivityMgr:EnterCheckReq(nActivityID, nRoleID)
		fnInnerCallback(bRet, sTipsCon, nSceneMixID) 
	end
end










