--PVP玩法管理器 --非活动实例管理器，而是活动实例管理器的管理器
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert


function CPVPActivityMgr:Ctor()
	self.m_tActivityMgr = {}   -- {nActivityID:oMgr, }
	self.m_tSceneActivityMap = {}  --{nMixID : ActivityInst, ...} --维护一个场景ID 关联 玩法实例Map，方便根据玩家场景同步数据
	setmetatable(self.m_tSceneActivityMap, {__mode = "kv"}) --设置为虚表，防止资源泄漏
end

function CPVPActivityMgr:Init()
	for k, tConf in pairs(ctPVPActivityConf) do --为每一个活动在对应的服上创建一个管理器
		assert(tConf.nPVPActivityID > 0, "PVP活动ID配置错误")
		--判断是否是指定逻辑服，如果不是，则不创建对应的mgr
		if CUtil:GetServiceID() == self:GetActivityServiceID(tConf.nPVPActivityID) then
			local oMgrClass = gtPVPActivityMgrMap[tConf.nActivityType]
			assert(oMgrClass, "活动类型未注册")
			local oMgrInst = oMgrClass:new(tConf.nPVPActivityID)
			self.m_tActivityMgr[tConf.nPVPActivityID] = oMgrInst
		end
	end
end

function CPVPActivityMgr:CreatePVPActivityScene(nSceneID, oActInst)
	local oDup = goDupMgr:CreateDup(nSceneID)
	assert(oDup, "创建场景失败")
	oDup:SetAutoCollected(false)
	local nDupMixID = oDup:GetMixID()
	self.m_tSceneActivityMap[nDupMixID] = oActInst
	return oDup
end

function CPVPActivityMgr:RemovePVPActivityScene(nDupMixID)
	goDupMgr:RemoveDup(nDupMixID)
	self.m_tSceneActivityMap[nDupMixID] = nil
end

function CPVPActivityMgr:GetActivityInstByDupMixID(nDupMixID)
	assert(nDupMixID and nDupMixID > 0, "参数错误")
	return self.m_tSceneActivityMap[nDupMixID]
end

function CPVPActivityMgr:GetActivitySceneConf(nActivityID, nFixParam)
	assert(nActivityID > 0, "参数错误")
	local tConf = ctPVPActivityConf[nActivityID]
	assert(tConf, "配置不存在")
	local tSceneConf = nil
	if not nFixParam then
		tSceneConf = ctDupConf[tConf.tSceneID[1][1]]
	else
		for k , v in pairs(tConf.tSceneID) do
			if v[2] == nFixParam then
				tSceneConf = ctDupConf[v[1]]
				break
			end
		end
	end
	assert(tSceneConf, "配置错误，场景配置不存在")
	return tSceneConf
end

function CPVPActivityMgr:GetActivityServiceID(nActivityID, nFixParam)
	local tConf = CPVPActivityMgr:GetActivitySceneConf(nActivityID, nFixParam)
	return tConf.nLogic
end

--获取PVP活动实例的管理器
function CPVPActivityMgr:GetActivityInstMgr(nActivityID) 
	return self.m_tActivityMgr[nActivityID]
end

--根据角色和活动ID，获取活动实例
function CPVPActivityMgr:GetActivityByID(nActivityID, ...)
	assert(nActivityID > 0, "参数错误")
	local oMgr = self.m_tActivityMgr[nActivityID]
	assert(oMgr, "活动管理器不存在")
	local oInst = oMgr:GetInst(...)
	return oInst
end

function CPVPActivityMgr:Release()
	for k, oMgr in pairs(self.m_tActivityMgr) do
		oMgr:Release()
	end
end

--------------------------------------------------
--检查当前能否参加该活动
--fnCallback(bRet, sReason, nDupMixID) --bRet是否可参加,sReason不可参加原因
--nDupMixID,如果可参加，活动场景ID
function CPVPActivityMgr:EnterCheck(oRole, nActivityID, fnCallback)
	if not nActivityID or nActivityID <= 0 then 
		return 
	end
	local tConf = ctPVPActivityConf[nActivityID]
	if not tConf then 
		oRole:Tips("活动不存在")
		return 
	end
	local oMgrClass = gtPVPActivityMgrMap[tConf.nActivityType]
	assert(oMgrClass, "活动类型未注册")
	oMgrClass:EnterCheck(oRole, nActivityID)
end

--玩家进入活动场景请求
function CPVPActivityMgr:EnterReq(oRole, nActivityID)  --请注意，这里可能分布在不同的逻辑服，此时，世界服上的logicServer上很可能是没有oRole对象的
	if not nActivityID or nActivityID <= 0 then 
		return 
	end
	local tConf = ctPVPActivityConf[nActivityID]
	if not tConf then 
		oRole:Tips("活动不存在")
		return 
	end
	local oMgrClass = gtPVPActivityMgrMap[tConf.nActivityType]
	assert(oMgrClass, "活动类型未注册")
	oMgrClass:EnterReq(oRole, nActivityID)
end

-- function CPVPActivityMgr:GetCheckTips(nActivityID)
-- 	local sTipsContent = "活动尚未开启"
-- 	if nActivityID == 1004 then
-- 		oMgr = self.m_tActivityMgr[nActivityID]
-- 		if oMgr and oMgr:IsOpen() then 
-- 			local nMatchUnion = oMgr:GetMatchedUnion()
-- 			sTipsContent = "活动匹配轮空，详情请查看活动结束后发送的邮件" 
-- 		end
-- 	end
-- 	return sTipsContent
-- end

--针对具体活动实例的进入检查请求   服务器发起
function CPVPActivityMgr:EnterCheckReq(nActivityID, nRoleID, ...)
	if nActivityID <= 0 then
		return 
	end
	local tConf = ctPVPActivityConf[nActivityID]
	if not tConf then 
		return 
	end
	local oInst = self:GetActivityByID(nActivityID, ...)
	if not oInst then
		--找不到活动实例，也可能是活动满足结束条件，提前结束销毁引起的
		local sTipsContent = "活动尚未开启"
		if nActivityID == gtDailyID.eUnionArena then
			oMgr = self.m_tActivityMgr[nActivityID]
			if oMgr and oMgr:IsOpen() then 
				if oMgr:IsJoinMatch(...) then 
					if oMgr:IsMatchEmpty(...) then 
						sTipsContent = "活动匹配轮空，详情请查看活动邮件" 
					end
				else
					sTipsContent = "帮会未达到参与活动条件"
				end
			else
				sTipsContent = "活动已结束"
			end
		end
		-- local nOpenStamp = CDailyActivity:GetStartStamp(nActivityID)
		-- local nEndStamp = CDailyActivity:GetEndStamp(nActivityID)
		-- local nTimeStamp = os.time()
		-- if nTimeStamp > nOpenStamp and nTimeStamp < nEndStamp then
		-- 	sTipsContent = "活动已结束"
		-- end
		return false, sTipsContent
	end
	local bPrepare = oInst:IsPrepare()
	if not bPrepare then 
		return false, "当前已过准备期，无法进入"
	end
	if oInst:GetMaxJoinNum() <= oInst:GetRoleNum() then 
		return false, "当前活动人数已满，无法进入"
	end
	local bRet,sReason = oInst:EnterCheckReq(nRoleID,...)
	if not bRet then
		return bRet,sReason
	end
	return true, "", oInst:GetScene():GetMixID()
end

function CPVPActivityMgr:GetPVPActivityArgs(oRole,nActivityID)
	if nActivityID == 1004 then
		return oRole:GetUnionID()
	else
		return oRole:GetSchool()
	end
end

--获取活动信息
function CPVPActivityMgr:SyncPVPActivityInfo(oRole, nActivityID)
	local nArgs = self:GetPVPActivityArgs(oRole,nActivityID)
	local oActivityInst = self:GetActivityByID(nActivityID, nArgs)
	-- assert(oActivityInst, "活动未开启")
	if not oActivityInst then 
		return 
	end
	oActivityInst:SyncPVPActivityInfo(oRole)
end

--获取活动玩家信息
function CPVPActivityMgr:SyncRoleData(oRole, nActivityID)
	local nArgs = self:GetPVPActivityArgs(oRole,nActivityID)
	local oActivityInst = self:GetActivityByID(nActivityID, nArgs)
	-- assert(oActivityInst, "活动未开启")
	if not oActivityInst then 
		return 
	end
	oActivityInst:SyncRoleData(oRole)
end

--获取活动排行榜数据
function CPVPActivityMgr:SyncRankData(oRole, nActivityID, nPageNum)
	local nArgs = self:GetPVPActivityArgs(oRole,nActivityID)
	local oActivityInst = self:GetActivityByID(nActivityID,nArgs)
	-- assert(oActivityInst, "活动未开启")
	if not oActivityInst then 
		return 
	end
	oActivityInst:SyncRankData(oRole, nPageNum)
end

--发起战斗请求
function CPVPActivityMgr:BattleReq(oRole, nActivityID, nEnemyID)
	local nArgs = self:GetPVPActivityArgs(oRole,nActivityID)
	local oActivityInst = self:GetActivityByID(nActivityID,nArgs)
	-- assert(oActivityInst, "活动未开启")
	if not oActivityInst then 
		return 
	end
	oActivityInst:BattleReq(oRole, nEnemyID)
end

function CPVPActivityMgr:LeaveReq(oRole)
	if oRole:IsInBattle() then
		oRole:Tips("正在战斗中，无法退出")
		return
	end
	local tCurDup = oRole:GetCurrDup()
	local tLastDup = oRole:GetLastDup()
	if tCurDup[1] == tLastDup[2] then
		return
	end
	oRole:EnterLastCity()
end

function CPVPActivityMgr:MatchTeamReq(oRole, nActivityID) 
	local nArgs = self:GetPVPActivityArgs(oRole,nActivityID)
	local oActivityInst = self:GetActivityByID(nActivityID, nArgs)
	-- assert(oActivityInst, "活动未开启")
	if not oActivityInst then 
		return 
	end
	oActivityInst:QuickMatchTeamReq(oRole)
end

function CPVPActivityMgr:CancelMatchTeamReq(oRole, nActivityID)
	local nArgs = self:GetPVPActivityArgs(oRole,nActivityID)
	local oActivityInst = self:GetActivityByID(nActivityID, nArgs)
	if not oActivityInst then 
		return
	end
	oActivityInst:CancelMatchTeamReq(oRole)
end

--GM重新开启活动(如果当前活动处于开启状态，则会强制结束，并重新开始)
function CPVPActivityMgr:GMRestart(nActivityID, nPrepareLastTime, nLastTime)
	print("GM重新开启活动, ActivityID:"..nActivityID)
	local oActivityMgr = self.m_tActivityMgr[nActivityID]
	if not oActivityMgr then
		print("PVP活动<"..nActivityID..">管理器不存在，请检查目标服务器是否正确")
		return false, "PVP活动管理器不存在，请检查目标服务器是否正确"
	end
	return oActivityMgr:GMRestart(nPrepareLastTime, nLastTime)
end

function CPVPActivityMgr:CheckStatus(nActivityID) 
	local oInstMgr = self:GetActivityInstMgr(nActivityID)
	return oInstMgr:IsOpen()
end

--------------------------------------------------
