--副本玩法管理器
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--死亡副本检测时间
local nDeadBattleDupCheckInterval = 60

function CBattleDupMgr:Ctor()
	self.m_nAutoID = 0
	self.m_tBattleDupMap = {}

	self.m_nTick = GetGModule("TimerMgr"):Interval(nDeadBattleDupCheckInterval, function() self:CheckDeadBattleDupTimer() end)
end

function CBattleDupMgr:Release() 
	GetGModule("TimerMgr"):Clear(self.m_nTick)

	for _, oBattle in pairs(self.m_tBattleDupMap) do
		oBattle:Release()
	end
end

function CBattleDupMgr:GenBattleDupID()
	self.m_nAutoID = self.m_nAutoID%0x7FFFFFFF+1
	return self.m_nAutoID
end

function CBattleDupMgr:GetBattleDup(nBattleDupID)
	return self.m_tBattleDupMap[nBattleDupID]
end

function CBattleDupMgr:CheckDeadBattleDupTimer()
	for nID, oBattle in pairs(self.m_tBattleDupMap) do
		if not oBattle:HasRole() then
			oBattle.m_nDeadTimes = (oBattle.m_nDeadTimes or 0) + 1
		else
			oBattle.m_nDeadTimes = 0
		end
		if (oBattle.m_nDeadTimes or 0) >= 3 then
			self:DestroyBattleDup(nID)
			LuaTrace("销毁死亡的副本玩法", oBattle:GetConf())
		end
	end
end

--创建战斗副本
--@fnCallback 创建副本成功回调
--@bRemote 别的服务请求创建副本
function CBattleDupMgr:CreateBattleDup(nType, fnCallback, bRemote, nServerID)
	print("CBattleDupMgr:CreateBattleDup****", nType, bRemote)	
	assert(bRemote or fnCallback, "参数错误")
	if not nServerID then 
		nServerID = gnServerID
	end
	
	local cClass = gtBattleDupClass[nType]
	if not cClass then
		return LuaTrace("副本玩法未实现:"..nType)
	end
	local tDupList = ctBattleDupConf[nType].tDupList
	if tDupList[1][1] <= 0 then
		return LuaTrace("副本玩法配置不存在:"..nType)
	end

	--副本在当前逻辑服
	local tDupConf = assert(ctDupConf[tDupList[1][1]])
	if tDupConf.nLogic == CUtil:GetServiceID() then
		local nID = self:GenBattleDupID()
		local oBattleDup = cClass:new(nID, nType)
		self.m_tBattleDupMap[nID] = oBattleDup
		local nDupMixID = oBattleDup:GetDupMixID(1)
		if bRemote then --远程创建副本
			return nDupMixID
		end
		fnCallback(nDupMixID)

	--副本不在当前逻辑服
	else
		local nServerID = tDupConf.nLogic>=100 and gnWorldServerID or nServerID
		Network:RMCall("WCreateBatteDupReq", function(nDupMixID)
			if not nDupMixID then
				return LuaTrace("创建玩法副本失败 TYPE:", nType)
			end
			fnCallback(nDupMixID)
		end, nServerID, tDupConf.nLogic, 0, nType)

	end
end

--销毁副本
function CBattleDupMgr:DestroyBattleDup(nBattleDupID)
	local oBattleDup = self:GetBattleDup(nBattleDupID)
	if not oBattleDup then return end
	self.m_tBattleDupMap[nBattleDupID] = nil
	oBattleDup:Release()	
end

--销毁指定类型的玩法副本(PVEGM命令开启调用)
function CBattleDupMgr:DestroyAssignTypeBattleDup(nType)
	for nBattleDupID, oBattleDup in pairs(self.m_tBattleDupMap) do
		if oBattleDup:GetType() == nType and oBattleDup.ActEnd then
			oBattleDup:ActEnd()
		end
	end
end

--进入玩法副本请求
function CBattleDupMgr:EnterBattleDupReq(oRole, nType)
	local cClass = gtBattleDupClass[nType]
	if not cClass then
		return oRole:Tips("副本玩法未实现:"..nType)
	end

	local oCurrDupObj = oRole:GetCurrDupObj()
	local tCurrDupConf = oCurrDupObj and oCurrDupObj:GetConf()
	-- local tTarBattleDupConf = ctBattleDupConf[nType]
	-- local tTarDupConf = ctDupConf[tTarBattleDupConf.]
	--策划要求副本中副本跳副本询问拦截
	if tCurrDupConf and tCurrDupConf.nType == CDupBase.tType.eDup then
		local tMsg = {sCont="是否确定离开当前副本？", tOption={"取消", "确定"}, nTimeOut=30}
        goClientCall:CallWait("ConfirmRet", function(tData)
            if tData.nSelIdx == 1 then
                return
			elseif tData.nSelIdx == 2 then
				--先去中转地图
				if goFBTransitScene then
					if oRole:IsLeader() or oRole:GetTeamID() <= 0 then
						oRole:SetTarBattleDupType(nType)
					end
					goFBTransitScene:EnterFBTransitScene(oRole)
				else
					local function CallBack(nMixID, nDupID)
						assert(ctDupConf[nDupID], "没有此场景配置")
						local tBornPos = ctDupConf[nDupID].tBorn[1]
						local nFace = ctDupConf[nDupID].nFace
						--队长或者没有队伍的角色才记录，队员不记录
						if oRole:IsLeader() or oRole:GetTeamID() <= 0 then
							oRole:SetTarBattleDupType(nType)
						end
						oRole:EnterScene(nMixID, tBornPos[1],  tBornPos[2], -1, nFace)
					end
					Network:RMCall("GetFBTransitSceneMixID", CallBack, oRole:GetStayServer(), 101, oRole:GetSession())
				end
            end
		end, oRole, tMsg)
	else
		cClass:EnterBattleDupReq(oRole)
	end

end

--通用的离开副本场景逻辑
function CBattleDupMgr:CommonLeaveDup(oRole)
	if not oRole then return end
	local nPreDupMixID = oRole:GetDupMixID()
	local nRoleID = oRole:GetID()
	local fnConfirmCallback = function(tData)
		oRole = goPlayerMgr:GetRoleByID(nRoleID)
		if not oRole then return end  --回调期间，角色离开了当前逻辑服
		if tData.nSelIdx == 2 then 
			self:IsPVEActiviCheck(oRole)
			--防止玩家选择过程中，队长切换到当前逻辑服其他场景，玩家跟随离开了当前场景
			local nCurDupMixID = oRole:GetDupMixID()
			if nPreDupMixID == nCurDupMixID then 
				oRole:EnterLastCity()
			end
		end
	end
	local sTipsContent = "是否确定离开当前副本？"
	local tMsg = {sCont=sTipsContent, tOption={"取消", "确定"}, nTimeOut=15}
	goClientCall:CallWait("ConfirmRet", fnConfirmCallback, oRole, tMsg)
end

function CBattleDupMgr:IsPVPActivityScene(nDupConfID)
	for k, tConf in pairs(ctPVPActivityConf) do 
		for _, tScene in pairs(tConf.tSceneID) do 
			if tScene[1] == nDupConfID then 
				return true 
			end
		end
	end
	return false
end

function CBattleDupMgr:IsPVEActiviCheck(oRole)
	local oDup = oRole:GetCurrDupObj() 
	local oBattleDup = goBattleDupMgr:GetBattleDup(oRole:GetBattleDupID())
	if oDup and oBattleDup and oBattleDup.PVELeaveCheck then
		local tDupConf = oDup:GetConf()
		if tDupConf.nBattleType > 200 and tDupConf.nBattleType < 300 then
			oBattleDup:PVELeaveCheck(oRole)
		end
	end
end

--离开玩法副本请求
function CBattleDupMgr:LeaveBattleDupReq(oRole)
	if not oRole then return end

	local nCurDupMixID = oRole:GetDupMixID()
	if not nCurDupMixID or nCurDupMixID <= 0 then 
		self:CommonLeaveDup(oRole)
		return 
	end
	local oDup = goDupMgr:GetDup(nCurDupMixID)
	if not oDup then 
		self:CommonLeaveDup(oRole)
		return
	end
	local tDupConf = oDup:GetConf()
	assert(tDupConf)
	if tDupConf.nType ~= CDupBase.tType.eDup then 
		-- self:CommonLeaveDup(oRole)
		return 
	end

	--PVP场景，离开，现在前端也是调用的这个接口
	if self:IsPVPActivityScene(tDupConf.nID) then 
		goPVPActivityMgr:LeaveReq(oRole)
		return 
	end

	local nBattleDupID = oRole:GetBattleDupID()
	local oBattleDup = self:GetBattleDup(nBattleDupID)
	if not oBattleDup then 
		self:CommonLeaveDup(oRole)
		return 
	end

	if oBattleDup.Leave then 
		oBattleDup:Leave(oRole)
	else 
		self:CommonLeaveDup(oRole)
    end
end

function CBattleDupMgr:EnterFBTransitSceneReq(oRole)
	if oRole:IsLeader() then
		local function OnLeaderLeaveTickAllMem(nTeamID, tTeam)
			for nKey, tRoleData in pairs(tTeam) do
				--判断是在副本内才踢出
				local oRole = goPlayerMgr:GetRoleByID(tRoleData.nRoleID)
				if not oRole then return end
				local oDup = oRole:GetCurrDupObj()
				if not oDup then return end
				local tConf = oDup:GetConf()
				if tConf.nBattleType>0 and oRole:GetTeamID() == nTeamID then
					goFBTransitScene:EnterFBTransitScene(oRole)
				end 
			end
		end
		oRole:GetTeam(OnLeaderLeaveTickAllMem)
	else
		goFBTransitScene:EnterFBTransitScene(oRole)
	end
end
