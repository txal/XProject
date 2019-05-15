--邀请系统
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CInvite:Ctor()
	self.m_bDirty = false
	self.m_tDownlineMap = {} 	--{[邀请者iD]={nGiftNum=0,nYuanBao=0,[被邀请者ID]={nTeamID=0,nTime=0},...},...} 下线映射
	self.m_tUplineMap = {} 		--上线映射{[被邀请id]=邀请id,...}
end

function CInvite:OnRelease()
	goTimerMgr:Clear(self.m_nAutoSaveTimer)
	self.m_nAutoSaveTimer = nil
	self:SaveData()
end

function CInvite:LoadData()
	local oDB = goDBMgr:GetSSDB(gnServerID, "global", GF.GetServiceID())
	local sData = oDB:HGet(gtDBDef.sInviteDB, "data")
	if sData == "" then
		return
	end
	local tData = cjson.decode(sData)
	self.m_tDownlineMap = tData.m_tDownlineMap
	self.m_tUplineMap = tData.m_tUplineMap

	self.m_nAutoSaveTimer = goTimerMgr:Interval(gnAutoSaveTime, function() self:SaveData() end)
end

function CInvite:SaveData()
	if not self:IsDirty() then
		return
	end
	local tData = {}
	tData.m_tDownlineMap = self.m_tDownlineMap
	tData.m_tUplineMap = self.m_tUplineMap
	local oDB = goDBMgr:GetSSDB(gnServerID, "global", GF.GetServiceID())
	oDB:HSet(gtDBDef.sInviteDB, "data", cjson.encode(tData))
	self:MarkDirty(false)
end

function CInvite:IsDirty() return self.m_bDirty end
function CInvite:MarkDirty(bDirty) self.m_bDirty = bDirty end

--上线
function CInvite:Online(oRole)
	self:SyncInviteInfo(oRole:GetID())
end

--取下线信息
function CInvite:GetDownline(nSrcRoleID, nTarRoleID)
	if not self.m_tDownlineMap[nSrcRoleID] then
		return
	end
	return self.m_tDownlineMap[nSrcRoleID][nTarRoleID]
end

--去上线角色ID
function CInvite:GetUpline(nRoleID)
	return self.m_tUplineMap[nRoleID]
end

--添加邀请
--@nSrcRoleID 邀请者角色ID
--@nTarRoleID 被邀请者角色ID
function CInvite:AddInvite(nSrcRoleID, nTarRoleID)
	if nSrcRoleID == nTarRoleID then
		return
	end
	local oSrcRole = goGPlayerMgr:GetRoleByID(nSrcRoleID)
	local oTarRole = goGPlayerMgr:GetRoleByID(nTarRoleID)
	if not oSrcRole then
		return LuaTrace(nSrcRoleID, "邀请者不存在，邀请失败")
	end
	if not oTarRole then
		return LuaTrace(nTarRoleID, "被邀请者不存在，邀请失败")
	end

	if self:GetUpline(nTarRoleID) then
		return LuaTrace(nTarRoleID, "被邀请者已有上线，邀请失败")
	end
	if self:GetDownline(nSrcRoleID, nTarRoleID) then
		return LuaTrace(nSrcRoleID, nTarRoleID, "已经邀请过了")
	end

	self.m_tDownlineMap[nSrcRoleID] = self.m_tDownlineMap[nSrcRoleID] or {}
	self.m_tDownlineMap[nSrcRoleID][nTarRoleID] = {nTime=os.time()}
	self.m_tUplineMap[nTarRoleID] = nSrcRoleID
	self:MarkDirty(true)
    self:SyncInviteInfo(nSrcRoleID)

	--申请加入队伍
    local oTeam = goTeamMgr:GetTeamByRoleID(nSrcRoleID)
    if oTeam then
    	oTeam:JoinApplyReq(oTarRole)
    end
	goLogger:InviteLog(oSrcRole, oTarRole)
end

--师门任务完成
function CInvite:OnMasterTaskComplete(oRole)
	local nUplineRoleID = self:GetUpline(oRole:GetID())
	if not nUplineRoleID then
		return
	end
	local tDownline = self:GetDownline(nUplineRoleID, oRole:GetID())
	if not tDownline then
		return
	end
	--1表示已经获得了礼包
	if tDownline.nMasterTaskState == 1 then
		return 
	end
	tDownline.nMasterTaskTimes = (tDownline.nMasterTaskTimes or 0) + 1
	if oRole:GetLevel() >= 60 and tDownline.nMasterTaskTimes >= 10 then
		tDownline.nMasterTaskState = 1
		local tDownlineMap = self.m_tDownlineMap[nUplineRoleID]
		tDownlineMap.nGiftNum = (tDownlineMap.nGiftNum or 0) + 1
	end
	self:SyncInviteInfo(nUplineRoleID)
	self:MarkDirty(true)
end

--充值成功
function CInvite:OnRechargeSuccess(oRole, nYuanBao)
	local nUplineRoleID = self:GetUpline(oRole:GetID())
	if not nUplineRoleID then
		return
	end
	local tDownline = self:GetDownline(nUplineRoleID, oRole:GetID())
	if not tDownline then
		return
	end
	local nZeroTime = os.ZeroTime(tDownline.nTime)
	if os.time() - nZeroTime >= 30*24*3600 then
		return
	end
	local tDownlineMap = self.m_tDownlineMap[nUplineRoleID]
	tDownlineMap.nYuanbao = (tDownlineMap.nYuanbao or 0) + math.floor(nYuanBao*0.05)
	self:MarkDirty(true)
	self:SyncInviteInfo(nUplineRoleID)
end

--同步邀请信息
function CInvite:SyncInviteInfo(nRoleID)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole:IsOnline() then
		return
	end
	local tMsg = {
		nGiftNum = 0,
		nYuanBao = 0,
		nDownlines = 0,
	}
	local tDownlineMap = self.m_tDownlineMap[nRoleID]
	if tDownlineMap then
		tMsg.nGiftNum = tDownlineMap.nGiftNum or 0
		tMsg.nYuanBao = tDownlineMap.nYuanBao or 0
		for _, v in pairs(tDownlineMap) do
			if type(v) == "table" then
				tMsg.nDownlines = tMsg.nDownlines + 1
			end
		end
	end
	oRole:SendMsg("InviteInfoRet", tMsg)
end

--领取奖励
function CInvite:InviteAwardReq(oRole, nType)
	assert(nType == 1 or nType == 2, "参数错误")

	local tDownlineMap = self.m_tDownlineMap[oRole:GetID()]
	if not tDownlineMap then
		return oRole:Tips("您还没有邀请")
	end

	if nType == 1 then --礼包
		local tDownlineMap = self.m_tDownlineMap[oRole:GetID()]
		if (tDownlineMap.nGiftNum or 0) <= 0 then
			return oRole:Tips("没有可领取的礼包")
		end
		local nGiftNum = tDownlineMap.nGiftNum 
		tDownlineMap.nGiftNum = 0
		self:MarkDirty(true)

		local tItemList = {{nType=gtItemType.eProp, nID=ctInviteConf[1].nGiftID, nNum=nGiftNum}}	
		oRole:AddItem(tItemList, "邀请奖励", function(bRes)
			if not bRes then
				tDownlineMap.nGiftNum = nGiftNum
				self:MarkDirty(true)
				self:SyncInviteInfo(oRole:GetID())
			end
		end)

	elseif nType == 2 then --绑定元宝
		local tDownlineMap = self.m_tDownlineMap[oRole:GetID()]
		if (tDownlineMap.nYuanBao or 0) <= 0 then
			return oRole:Tips("没有可领取的元宝")
		end
		local nYuanBao = tDownlineMap.nYuanBao 
		tDownlineMap.nYuanBao = 0
		self:MarkDirty(true)

		local tItemList = {{nType=gtItemType.eCurr, nID=gtCurrType.eBYuanBao, nNum=nYuanBao}}	
		oRole:AddItem(tItemList, "邀请奖励", function(bRes)
			if not bRes then
				tDownlineMap.nYuanBao = nYuanBao
				self:MarkDirty(true)
				self:SyncInviteInfo(oRole:GetID())
			end
		end)
	end
end


goInvite = goInvite or CInvite:new()