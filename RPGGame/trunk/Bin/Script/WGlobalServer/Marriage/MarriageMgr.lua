--婚姻系统
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

gtMarriageState = 
{
	eSingle = 0,      --未婚
	eMarried = 1,     --已婚
	eDivorcing = 2,   --离婚中
}

local nPropWeddingCandyID = 11009

--玩家婚姻数据，方便做扩展
function CRoleMarriage:Ctor(nRoleID)
	--角色账号删除了，全部提示角色不存在
	self.m_nRoleID = nRoleID
	self.m_nSpouseID = 0             --当前的配偶关系ID
	self.m_nLastDivorceStamp = 0     --最近一次离婚时间
	self.m_tMarriageRecord = {}      --历史婚姻记录{MarriageStamp, DivorceStamp, SpouseID, CoupleNum}
	self.m_tBlessGiftRecord = {}

	self.m_bDirty = false

	self.m_tInviteSilenceMap = {}    --不存DB，该次登录下，邀请默认拒绝
end

function CRoleMarriage:SaveData()
	local tData = {}
	tData.nRoleID = self.m_nRoleID
	tData.nSpouseID = self.m_nSpouseID
	tData.nLastDivorceStamp = self.m_nLastDivorceStamp
	tData.tMarriageRecord = self.m_tMarriageRecord
	tData.tBlessGiftRecord = self.m_tBlessGiftRecord
	return tData
end

function CRoleMarriage:LoadData(tData)
	if not tData then
		return
	end
	--self.m_nRoleID = tData.nRoleID
	self.m_nSpouseID = tData.nSpouseID
	self.m_nLastDivorceStamp = tData.nLastDivorceStamp
	self.m_tMarriageRecord = tData.tMarriageRecord
	self.m_tBlessGiftRecord = tData.tBlessGiftRecord
end

function CRoleMarriage:GetID() return self.m_nRoleID end
function CRoleMarriage:MarkDirty(bDirty) 
	self.m_bDirty = bDirty
	if self.m_bDirty then 
		goMarriageMgr.m_tRoleMarriageSaveQueue:Push(self.m_nRoleID, self)
	end
end
function CRoleMarriage:IsDirty() return self.m_bDirty end
function CRoleMarriage:GetLastDivorceStamp() return self.m_nLastDivorceStamp end
function CRoleMarriage:GetSpouse() return self.m_nSpouseID end

function CRoleMarriage:OnMarry(nTarID)
	assert(nTarID > 0)
	self.m_nSpouseID = nTarID
	self.m_tBlessGiftRecord = {}
	self:MarkDirty(true)

	local oRole = goGPlayerMgr:GetRoleByID(self:GetID())
	local oTarRole = goGPlayerMgr:GetRoleByID(nTarID)
	assert(oRole and oTarRole)
	--尝试删除上一次离婚的称号
	oRole:RemoveAppellation(gtAppellationIDDef.eForceDivorce, 0)
	--添加夫妻称号
	local nAppeID = gtAppellationIDDef.eHusband
	if oRole:GetGender() ~= 1 then 
		nAppeID = gtAppellationIDDef.eWife
	end
	oRole:AddAppellation(nAppeID, {tNameParam={oTarRole:GetName()}}, oTarRole:GetID())

	--结婚活动
	local nServerID = oRole:GetServer()
	local nServiceID = goServerMgr:GetGlobalService(nServerID, 20)
	goRemoteCall:Call("MarriageActTriggerReq", nServerID, nServiceID, 0, oRole:GetID())
end

function CRoleMarriage:OnDivorce(nTarID, nTimeStamp)
	assert(nTarID and nTarID > 0)
	if self.m_nSpouseID > 0 then
		nTimeStamp = nTimeStamp or os.time()
		self.m_nSpouseID = 0
		self.m_nLastDivorceStamp = nTimeStamp
	end
	self.m_tBlessGiftRecord = {}
	self:MarkDirty(true)

	local oRole = goGPlayerMgr:GetRoleByID(self:GetID())
	assert(oRole)
	local nAppeID = gtAppellationIDDef.eHusband
	if oRole:GetGender() ~= 1 then 
		nAppeID = gtAppellationIDDef.eWife
	end
	--删除夫妻称号
	oRole:RemoveAppellation(nAppeID, nTarID)
	--添加离婚称号
	oRole:AddAppellation(gtAppellationIDDef.eForceDivorce)
end

--插入邀请屏蔽列表
function CRoleMarriage:InsertInviteSilenceMap(nRoleID)
	self.m_tInviteSilenceMap[nRoleID] = os.time()
end

function CRoleMarriage:IsInInviteSilenceMap(nRoleID)
	if not nRoleID then 
		return false 
	end
	return self.m_tInviteSilenceMap[nRoleID] and true or false
end

function CRoleMarriage:CleanInviteSilenceMap()
	self.m_tInviteSilenceMap = {}
end


-------------------------------------------------------------
-------------------------------------------------------------
function CMarriageMgr:Ctor()
	self.m_tCoupleMap = {}       --配偶map
	self.m_tRoleMap = {}         --{nRoleID:oMarriage, ...}
	self.m_tRoleCoupleMap = {}   --{nRoleID:oCouple, ...}
	self.m_nMarriageKey = 1      --编号
	--self.m_nCoupleNum = 0        --结婚玩家对数编号，和Key分离
	self.m_tDivorceList = {}         --{CoupleID, ...}  --申请离婚列表，不存DB
	self.m_bDirty = false

	self.m_tCoupleSaveQueue = CUniqCircleQueue:new()
	self.m_tRoleMarriageSaveQueue = CUniqCircleQueue:new()
	self.m_nTimer = nil
end

function CMarriageMgr:MarkDirty(bDirty) 
	self.m_bDirty = bDirty 
end
function CMarriageMgr:IsDirty() return self.m_bDirty end
function CMarriageMgr:Init()
	self.m_nTimer = goTimerMgr:Interval(60, function ()  self:Tick() end) 
	self:LoadData()
end

function CMarriageMgr:CheckDivorceExpiry()
	local tDivorceList = {}
	for k, v in pairs(self.m_tDivorceList) do
		local oCouple = self:GetCouple(k)
		if oCouple then
			if oCouple:GetState() == gtCoupleState.eDivorcing then
				if oCouple:GetDivorceCountdown() <= 0 then
					table.insert(tDivorceList, k)
				end
			end
		else
			table.insert(tDivorceList, k)
		end
	end
	for k, v in ipairs(tDivorceList) do
		self:DealDivorce(v)
		self.m_tDivorceList[v] = nil
	end
end

function CMarriageMgr:Tick()
	self:CheckDivorceExpiry()
	self:SaveData()
	-- self:DebugCheck()  --DEBUG用
end

function CMarriageMgr:OnRelease()
	goTimerMgr:Clear(self.m_nTimer)
	self.m_nTimer = nil
	self:SaveData()
end

function CMarriageMgr:SaveSysData()
	if not self:IsDirty() then
		return
	end
	local tData = {}
	tData.nMarriageKey = self.m_nMarriageKey	
	local oDB = goDBMgr:GetSSDB(gnServerID, "global", GF.GetServiceID())
	oDB:HSet(gtDBDef.sMarriageSysDB, "marriagesysdata", cjson.encode(tData))
	self:MarkDirty(false)
end

function CMarriageMgr:SaveCoupleData()
	local nDirtyNum = self.m_tCoupleSaveQueue:Count()
	if nDirtyNum < 1 then
		return
	end
	local oDB = goDBMgr:GetSSDB(gnServerID, "global", GF.GetServiceID())
	for i = 1, nDirtyNum do
		local oCouple = self.m_tCoupleSaveQueue:Head()
		if oCouple then
			local tData = oCouple:SaveData()
			oDB:HSet(gtDBDef.sMarriageCoupleDB, oCouple:GetID(), cjson.encode(tData))
			oCouple:MarkDirty(false)
		end
		self.m_tCoupleSaveQueue:Pop()
	end
end

function CMarriageMgr:SavaMarriageData()
	local nDirtyNum = self.m_tRoleMarriageSaveQueue:Count()
	if nDirtyNum < 1 then
		return
	end
	local oDB = goDBMgr:GetSSDB(gnServerID, "global", GF.GetServiceID())
	for i = 1, nDirtyNum do
		local oRoleMarriage = self.m_tRoleMarriageSaveQueue:Head()
		if oRoleMarriage then
			local tData = oRoleMarriage:SaveData()
			oDB:HSet(gtDBDef.sRoleMarriageDB, oRoleMarriage:GetID(), cjson.encode(tData))
			oRoleMarriage:MarkDirty(false)
		end
		self.m_tRoleMarriageSaveQueue:Pop()
	end
end
function CMarriageMgr:SaveData()
	self:SaveSysData()
	self:SaveCoupleData()
	self:SavaMarriageData()
end

function CMarriageMgr:LoadSysData()
	local oDB = goDBMgr:GetSSDB(gnServerID, "global", GF.GetServiceID())
	local sData = oDB:HGet(gtDBDef.sMarriageSysDB, "marriagesysdata")
	if sData ~= "" then
		local tData = cjson.decode(sData)
		self.m_nMarriageKey = tData.nMarriageKey
	end
end

function CMarriageMgr:LoadCoupleData()
	local oDB = goDBMgr:GetSSDB(gnServerID, "global", GF.GetServiceID())
	local tKeys = oDB:HKeys(gtDBDef.sMarriageCoupleDB)
	for _, sID in ipairs(tKeys) do
		local sData = oDB:HGet(gtDBDef.sMarriageCoupleDB, sID)
		local tData = cjson.decode(sData)
		local nID = tData.nID
		local oCouple = CCouple:new(nID)
		oCouple:LoadData(tData)
		self.m_tCoupleMap[nID] = oCouple
		local nHusbandID = oCouple:GetHusbandID()
		local nWifeID = oCouple:GetWifeID()
		if nHusbandID > 0 then
			self.m_tRoleCoupleMap[nHusbandID] = oCouple
		end
		if nWifeID > 0 then
			self.m_tRoleCoupleMap[nWifeID] = oCouple
		end
		if oCouple:GetState() == gtCoupleState.eDivorcing then
			self.m_tDivorceList[nID] = nID
		end
		--TODO 尝试在此处修复错误数据
	end
end

function CMarriageMgr:LoadMarriageData()
	local oDB = goDBMgr:GetSSDB(gnServerID, "global", GF.GetServiceID())
	local tKeys = oDB:HKeys(gtDBDef.sRoleMarriageDB)
	for _, sRoleID in ipairs(tKeys) do
		local sData = oDB:HGet(gtDBDef.sRoleMarriageDB, sRoleID)
		local tData = cjson.decode(sData)
		local nRoleID = tData.nRoleID
		local oRoleMarriage = CRoleMarriage:new(nRoleID)
		oRoleMarriage:LoadData(tData)
		self.m_tRoleMap[nRoleID] = oRoleMarriage
	end
end

function CMarriageMgr:LoadData()
	self:LoadSysData()
	self:LoadMarriageData()
	self:LoadCoupleData()
	-- self:DebugCheck()
end

function CMarriageMgr:DebugCheck()
	--DEBUG用，发现偶尔有数据不正确的情况
	if not gbInnerServer then 
		return 
	end
	for nCoupleID, oCouple in pairs(self.m_tCoupleMap) do 
		local nHusbandID = oCouple:GetHusbandID()
		local nWifeID = oCouple:GetWifeID()
		local oHusbandMarr = self:GetRoleMarriage(nHusbandID)
		local oWifeMarr = self:GetRoleMarriage(nWifeID)
		assert(oHusbandMarr and oWifeMarr)
		if oHusbandMarr:GetSpouse() ~= nWifeID or oWifeMarr:GetSpouse() ~= nHusbandID then 
			assert(false, "数据错误")
		end
	end
end

function CMarriageMgr:GenKey()
	local nKey = self.m_nMarriageKey
	--self.m_nMarriageKey = self.m_nMarriageKey % 0x7fffffff + 1
	assert(nKey <= 0x7fffffff, "nKey已达上限")  --全区共享的，这个key不可以循环用
	self.m_nMarriageKey = self.m_nMarriageKey + 1
	self:MarkDirty(true)
	return nKey
end

--function CMarriageMgr:GetCoupleNum() return self.m_nCoupleNum end
function CMarriageMgr:GetCouple(nCoupleID) return self.m_tCoupleMap[nCoupleID] end
function CMarriageMgr:GetCoupleByRoleID(nRoleID) return self.m_tRoleCoupleMap[nRoleID] end
function CMarriageMgr:GetRoleMarriage(nRoleID, bInsert) 
	if not self.m_tRoleMap[nRoleID] then
		if not bInsert then
			return
		end
		self:InsertRoleMarriage(nRoleID)
	end
	return self.m_tRoleMap[nRoleID]
end

function CMarriageMgr:InsertRoleMarriage(nRoleID)
	assert(nRoleID > 0, "参数错误")
	if self.m_tRoleMap[nRoleID] then
		return
	end
	local oRoleMarr = CRoleMarriage:new(nRoleID)
	self.m_tRoleMap[nRoleID] = oRoleMarr
	oRoleMarr:MarkDirty(true)
	return oRoleMarr
end

--是否是夫妻
function CMarriageMgr:IsCouple(nRoleID, nTarID)
	local oRoleCouple = self:GetCoupleByRoleID(nRoleID)
	local oTarCouple = self:GetCoupleByRoleID(nTarID)
	if oRoleCouple and oTarCouple then
		if oRoleCouple:GetID() == oTarCouple:GetID() then
			return true
		end
	end
	return false
end

function CMarriageMgr:IsSysOpen(oRole, bTips)
	if not oRole then 
		return false 
	end
	return oRole:IsSysOpen(57, bTips)
end

function CMarriageMgr:Marry(nRoleID, nTarID)
	assert(nRoleID and nTarID, "参数错误")
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	local oTarRole = goGPlayerMgr:GetRoleByID(nTarID)
	assert(oRole and oTarRole, "数据错误")
	if not self:IsSysOpen(oRole, true) or not self:IsSysOpen(oTarRole, true) then 
		return 
	end 

	--再次检查下一些重要数据相关限制，做一下拦截
	--检查ID
	if nRoleID == nTarID then
		oRole:Tips("不能和自己结婚")
		return
	end
	if not oTarRole:IsOnline() then
		return oRole:Tips("对方已离线，无法申请结婚")
	end
	--检查性别
	local tRoleConf = oRole:GetConf()
	local tTarConf = oTarRole:GetConf()
	if tRoleConf.nGender == tTarConf.nGender then
		return
	end
	--检查是否已婚
	if self:GetCoupleByRoleID(nRoleID) or self:GetCoupleByRoleID(nTarID) then
		return
	end

	local oRoleMarr = self:GetRoleMarriage(nRoleID)
	local oTarMarr = self:GetRoleMarriage(nTarID)
	assert(oRoleMarr and oTarMarr, "玩家婚姻数据不存在")
	assert(oRoleMarr:GetSpouse() <= 0 and oTarMarr:GetSpouse() <= 0, "数据错误")

	--local nHusband = (tRoleConf.nGender == 1) and nRoleID or nTarID
	--local nWife = (tRoleConf.nGender == 2) and nRoleID or nTarID
	local nTimeStamp = os.time()
	local nCoupleID = self:GenKey()
	local oCouple = CCouple:new(nCoupleID)
	oCouple.m_nHusbandID = (tRoleConf.nGender == 1) and nRoleID or nTarID
	oCouple.m_nWifeID = (tRoleConf.nGender == 2) and nRoleID or nTarID
	oCouple.m_nMarriageStamp = nTimeStamp

	self.m_tCoupleMap[oCouple:GetID()] = oCouple
	self.m_tRoleCoupleMap[nRoleID] = oCouple
	self.m_tRoleCoupleMap[nTarID] = oCouple
	--self.m_nCoupleNum = self.m_nCoupleNum + 1
	--oCouple.m_nCoupleNum = self.m_nCoupleNum
	oCouple:MarkDirty(true)

	oRoleMarr:OnMarry(nTarID)
	oTarMarr:OnMarry(nRoleID)

	local tDate = os.date("*t")
	local nYear = tDate.year or 0 
	local nMonth = tDate.month or 0
	local nDay = tDate.day or 0


    local sContent = string.format("恭喜%s和%s在%d年%d月%d日在月老的见证下喜结良缘，成为本区第%d对夫妻，大家可前往月老处参加婚礼，还可以获得喜糖哦~~", 
        oRole:GetFormattedName(), oTarRole:GetFormattedName(), nYear, nMonth, nDay, nCoupleID)
	-- GF.SendSystemTalk("系统", sContent)
	GF.SendNotice(0, sContent)
	
	local sMailTitle = "喜糖礼盒"
	local sMailContentTemplate = "恭喜你和%s在%d年%d月%d日喜结良缘，成为本区第%d对夫妻，月老特别送上贺礼喜糖，可以自己使用或赠送宾朋。月老相信你们会永结同心、白头偕老！"
	local sRoleMailContent = string.format(sMailContentTemplate, oTarRole:GetName(), nYear, nMonth, nDay, nCoupleID)
	local sTarMailContent = string.format(sMailContentTemplate, oRole:GetName(), nYear, nMonth, nDay, nCoupleID)
	local tItemList = {{gtItemType.eProp, nPropWeddingCandyID, 20},}
	oRole:SendSysMail(sMailTitle, sRoleMailContent, tItemList)
	oTarRole:SendSysMail(sMailTitle, sTarMailContent, tItemList)
	--TODO 同步通知婚姻数据
	self:SendMarryNoticeToFriend(nRoleID, nTarID)
	self:SendMarryNoticeToFriend(nTarID, nRoleID)
	self:SyncLogicCache(nRoleID)
	self:SyncLogicCache(nTarID)
	return true
end

function CMarriageMgr:CheckMarry(nRoleID, nTarID, bAsk)
	assert(nRoleID, "参数错误")
	if not nTarID or nTarID <= 0 then 
		return 
	end
	assert(nRoleID ~= nTarID)

	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	local oTarRole = goGPlayerMgr:GetRoleByID(nTarID)
	assert(oRole and oTarRole, "数据错误")
	local bCanMarry = false
	local tCheckList = {
		bTeamAndGender = true,
		bLevel = true,
		bFriend = true,
		bMarriageState = true,
	}

	if not oRole:IsOnline() or not oTarRole:IsOnline() then 
		tCheckList.bTeamAndGender = false
	end

	if not bAsk then 
		local oTeam = goTeamMgr:GetTeamByRoleID(nRoleID)
		local oTarTeam = goTeamMgr:GetTeamByRoleID(nTarID)
		if not oTeam or not oTarTeam or oTeam:GetID() ~= oTarTeam:GetID() then
			tCheckList.bTeamAndGender = false
		end
		if oTeam:GetMembers() ~= 2 then
			tCheckList.bTeamAndGender = false
		end
		if oTeam:IsLeave(nRoleID) or oTeam:IsLeave(nTarID) then  --当前暂离
			tCheckList.bTeamAndGender = false
		end
	end

	--检查性别
	local tRoleConf = oRole:GetConf()
	local tTarConf = oTarRole:GetConf()
	if tRoleConf.nGender == tTarConf.nGender then
		tCheckList.bTeamAndGender = false
	end

	--检查等级
	if not (oRole:GetLevel() >= 15 and oTarRole:GetLevel() >= 15) then
		tCheckList.bLevel = false
	end


	--检查是否已婚
	if GF.IsRobot(nRoleID) or GF.IsRobot(nTarID) then
		tCheckList.bFriend = false
		tCheckList.bMarriageState = false
	else
		--检查好友关系及亲密度
		local oRoleFriend = goFriendMgr:GetFriend(nRoleID, nTarID)
		local oTarFriend = goFriendMgr:GetFriend(nTarID, nRoleID)
		if not oRoleFriend or not oTarFriend then
			tCheckList.bFriend = false	
		else
			if oRoleFriend:GetDegrees() < 1000 or oTarFriend:GetDegrees() < 1000 then
				tCheckList.bFriend = false
			end
		end

		if self:GetCoupleByRoleID(nRoleID) or self:GetCoupleByRoleID(nTarID) then
			tCheckList.bMarriageState = false
		end
		local oRoleMarr = self:GetRoleMarriage(nRoleID, true)
		local oTarMarr = self:GetRoleMarriage(nTarID, true)
		assert(oRoleMarr and oTarMarr, "玩家婚姻数据不存在")
		-- assert(oRoleMarr:GetSpouse() >= 0 and oTarMarr:GetSpouse() >= 0, "数据错误")

		--检查是否离婚时间未满72小时
		local nTimeStamp = math.max(os.time() - (72*60*60), 0)
		if oRoleMarr:GetLastDivorceStamp() > nTimeStamp or oTarMarr:GetLastDivorceStamp() > nTimeStamp then
			tCheckList.bMarriageState = false
		end
	end

	bCanMarry = true
	for k, v in pairs(tCheckList) do
		if v == false then
			bCanMarry = false
			break
		end
	end

	return bCanMarry, tCheckList
end

function CMarriageMgr:SendMarryNoticeToFriend(nRoleID, nSpouseID)
	assert(nRoleID and nSpouseID, "参数错误")
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	local oRoleMarr = self:GetRoleMarriage(nRoleID)
	assert(oRoleMarr, "数据错误")
	local tFriendList = goFriendMgr:GetFriendMap(nRoleID)
	oRoleMarr.m_tBlessGiftRecord = {}
	for k, v in pairs(tFriendList) do 
		if k ~= nSpouseID then
			oRoleMarr.m_tBlessGiftRecord[k] = {bSendGift = false}
		end
	end

	local oCouple = self:GetCoupleByRoleID(nRoleID)
	local tTalkConf = ctTalkConf["marrymessage"]  --TODO
	local sCont = string.format(tTalkConf.sContent, oCouple:GetID(),nRoleID)  --必须加上婚姻编号标识
	goFriendMgr:BroadcastFriendTalk(oRole, false, sCont, {[nSpouseID] = nSpouseID})
end

--结婚祝福，还需要判断，是否已祝福过，是否已过期，已祝福过或已过期的，不能再次祝福
function CMarriageMgr:SendMarriageBlessGift(oRole, nTarID, nCoupleID, nGiftLevel)
	assert(oRole and nTarID > 0 and nCoupleID > 0 and nGiftLevel > 0, "参数错误")
	local tGiftConf = ctMarriageGiftConf[nGiftLevel]
	if not tGiftConf then
		oRole:Tips("非法数据")
		return
	end

	local oTarRole = goGPlayerMgr:GetRoleByID(nTarID)
	if not oTarRole then
		oRole:Tips("目标玩家不存在")
		return
	end
	local oCouple = self:GetCoupleByRoleID(nTarID)
	if not oCouple or oCouple:GetID() ~= nCoupleID then
		oRole:Tips("消息已过期，无法赠送贺礼")
		return
	end

	local oTarMarr = self:GetRoleMarriage(nTarID)
	if not oTarMarr then
		return
	end
	local nRoleID = oRole:GetID()
	if nRoleID == nTarID then
		oRole:Tips("不能给自己送礼")
		return
	end
	if not oTarMarr.m_tBlessGiftRecord[nRoleID] then --不在列表中的玩家都不允许赠送，防止有玩家建小号作弊转移金币
		oRole:Tips("消息已过期，无法赠送贺礼")
		return
	end
	if oTarMarr.m_tBlessGiftRecord[nRoleID].bSendGift then
		oRole:Tips("不可重复送礼")
		return
	end
	local nTimeStamp = os.time()
	if math.abs(nTimeStamp - oCouple:GetMarriageStamp()) > (3*24*60*60) then
		oRole:Tips("消息已过期，无法赠送贺礼")
		return
	end

	local tCost = {}
	for k, v in ipairs(tGiftConf.tCostList) do
		if v[1] > 0 and v[2] > 0 and v[3] > 0 then
			table.insert(tCost, {nType = v[1], nID = v[2], nNum = v[3]})
		end
	end
	local tGiftList = {}
	for k, v in ipairs(tGiftConf.tGiftList) do
		if v[1] > 0 and v[2] > 0 and v[3] > 0 then
			table.insert(tGiftList, {v[1], v[2], v[3]})
		end
	end
	assert(#tCost >= 1 and #tGiftList >= 1, "结婚贺礼表配置不正确")

	local fnSubItemCallback = function (bRet)
		if not bRet then
			return
		end
		--玩家连点，赠送多次情况
		--rpc调用期间，状态已经发生变化
		if oTarMarr.m_tBlessGiftRecord[nRoleID].bSendGift then
			oRole:AddItem(tCost, "结婚贺礼回滚")
			return
		end
		oTarMarr.m_tBlessGiftRecord[nRoleID].bSendGift = true

		-- local sGiftContent = ""   --拼接，支持多个物品

		-- local bFirst = true 
		-- for k, v in ipairs(tGiftList) do
		-- 	if v[1] == gtItemType.eProp then --暂时只支持道具类型，后期更改
		-- 		if not bFirst then 
		-- 			sGiftContent = sGiftContent.."、"
		-- 		end
		-- 		sGiftContent = sGiftContent..v[3]..ctPropConf[v[2]].sName
		-- 		bFirst = false 
		-- 	end
		-- end

		local sMailTitle = "新婚快乐！百年好合"
		local sMailContentTemplate = "你的好朋友 %s 为你送上新婚祝福。祝愿新婚快乐，百年好合！特送上%s，聊表寸心"
		local sMailContent = string.format(sMailContentTemplate, oRole:GetName(), tGiftConf.sGiftName)

		oTarRole:SendSysMail(sMailTitle, sMailContent, tGiftList)
		oRole:Tips("赠送贺礼成功")
	end

	oRole:SubItemShowNotEnoughTips(tCost, "结婚贺礼", true, false, fnSubItemCallback)
end

function CMarriageMgr:CheckPalanquinRent(nRoleID)
	assert(nRoleID, "参数错误")
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	assert(oRole, "数据错误")

	local bCanRent = false
	--local sReason = "租赁花轿需要夫妻组队申请，请带上你的另一半再来吧！"
	local oTeam = goTeamMgr:GetTeamByRoleID(nRoleID)
	if not oTeam then
		return bCanRent, "租赁花轿需要夫妻组队申请，请带上你的另一半再来吧！"
	end
	local nTeamMemberNum = oTeam:GetMembers()
	if nTeamMemberNum < 2 then
		return bCanRent, "租赁花轿需要夫妻组队申请，请带上你的另一半再来吧！"
	end

	local nTarID = nil
	for k, v in pairs(oTeam:GetRoleList()) do
		if v.nRoleID ~= nRoleID then
			nTarID = v.nRoleID
			break
		end
	end
	assert(nTarID and nTarID > 0, "数据错误")
	if nRoleID == nTarID then
		return false, ""
	end

	if oTeam:IsLeave(nRoleID) or oTeam:IsLeave(nTarID) then  --当前暂离
		return bCanRent, "租赁花轿需要夫妻组队申请，请带上你的另一半再来吧！"
	end

	if nTeamMemberNum > 2 then
		return bCanRent, "你们人数有点多，我的花轿可坐不下！"
	end

	if not self:IsCouple(nRoleID, nTarID) then 
		return bCanRent, "你们俩不是夫妻关系，租赁花轿有些不太合适啊"
	end

	local oTarRole = goGPlayerMgr:GetRoleByID(nTarID)
	assert(oTarRole, "数据错误")
	if not oTarRole:IsOnline() then
		return bCanRent, "租赁花轿需要夫妻同时在线"
	end
	local oCouple = self:GetCoupleByRoleID(nRoleID)
	assert(oCouple)
	return true, "", {nHusband = oCouple:GetHusbandID(), nWife = oCouple:GetWifeID()}
end

function CMarriageMgr:GetRoleMarriageState(nRoleID)
	if GF.IsRobot(nRoleID) then 
		return 
	end
	local oRoleMarr = self:GetRoleMarriage(nRoleID, true)
	assert(oRoleMarr)
	local oCouple = self:GetCoupleByRoleID(nRoleID)
	if not oCouple then
		return gtMarriageState.eSingle
	else
		local nCoupleState = oCouple:GetState()
		if nCoupleState == gtCoupleState.eNormal then
			return gtMarriageState.eMarried
		elseif nCoupleState == gtCoupleState.eDivorcing then
			return gtMarriageState.eDivorcing
		else
			return gtMarriageState.eSingle
		end
	end
end

function CMarriageMgr:MarriageDataReq(oRole)
	local nRoleID = oRole:GetID()
	local oRoleMarr = self:GetRoleMarriage(nRoleID, true)
	assert(oRoleMarr)
	local oCouple = self:GetCoupleByRoleID(nRoleID)
	local tRetData = {}
	tRetData.nMarriageState = self:GetRoleMarriageState(nRoleID)
	if oCouple then
		local tMarriageData = {}
		tMarriageData.nID = oCouple:GetSpouseID(nRoleID)
		local oSpouse = goGPlayerMgr:GetRoleByID(tMarriageData.nID)
		tMarriageData.sName  = oSpouse:GetName()
		tMarriageData.sHeader = oSpouse:GetHeader()
		tMarriageData.nGender = oSpouse:GetGender()
		tMarriageData.nSchool = oSpouse:GetSchool()
		tMarriageData.nLevel = oSpouse:GetLevel()
		tMarriageData.nMarriageStamp = oCouple:GetMarriageStamp()
		tMarriageData.nMarriageID = oCouple:GetID()
		tMarriageData.nMarriageTime = math.max(0, os.time() - tMarriageData.nMarriageStamp)
		tRetData.tMarriage = tMarriageData

		if gtCoupleState.eDivorcing == oCouple:GetState() then
			tRetData.nDivorceRoleID = oCouple:GetDivorceRole()
			tRetData.nDivorceCountdown = oCouple:GetDivorceCountdown()
			tRetData.nDivorceStamp = oCouple:GetDivorceStamp()
		end
	end
	oRole:SendMsg("RoleMarriageDataRet", tRetData)
end

function CMarriageMgr:MarriageActionDataReq(oRole)
	local nRoleID = oRole:GetID()
	local tRetData = {}
	tRetData.nMarriageState = self:GetRoleMarriageState(nRoleID)
	if tRetData.nMarriageState ~= gtMarriageState.eSingle then
		local oRoleMarr = self:GetRoleMarriage(nRoleID)
		local oCouple = self:GetCoupleByRoleID(nRoleID)
		if oCouple:GetState() == gtCoupleState.eDivorcing then
			tRetData.bDivorceRole = (oCouple:GetDivorceRole() == nRoleID) and true or false
			tRetData.nDivorceCountdown = oCouple:GetDivorceCountdown()
		end
		tRetData.nMarriageTime = math.max(0, os.time() - oCouple:GetMarriageStamp())
	end
	oRole:SendMsg("MarriageActionDataRet", tRetData)
end

--结婚询问条件检查请求
function CMarriageMgr:MarriageAskCheckReq(oRole, nTarID)
	if not nTarID or nTarID <= 0 or oRole:GetID() == nTarID then 
		oRole:Tips("错误数据")
		return 
	end
	local oTarRole = goGPlayerMgr:GetRoleByID(nTarID)
	if not oTarRole then 
		oRole:Tips("对方已离线")
		return 
	end
	local nRoleID = oRole:GetID()
	local bCanMarry, tCheckList = self:CheckMarry(nRoleID, nTarID, true)
	local tRetData = {}
	tRetData.bGender = tCheckList.bTeamAndGender
	tRetData.bLevel = tCheckList.bLevel
	tRetData.bFriend = tCheckList.bFriend
	tRetData.bMarriage = tCheckList.bMarriageState
	tRetData.nTarRoleID = nTarID
	oRole:SendMsg("MarriageAskCheckRet", tRetData)
end

--发起结婚询问请求
function CMarriageMgr:MarriageAskReq(oRole, nTarID)
	if not nTarID or nTarID <= 0 or oRole:GetID() == nTarID then 
		oRole:Tips("错误数据")
		return 
	end
	local oTarRole = goGPlayerMgr:GetRoleByID(nTarID)
	if not oTarRole or not oTarRole:IsOnline() then 
		oRole:Tips("对方已离线")
		return 
	end
	local oTarMarr = self:GetRoleMarriage(nTarID)
	assert(oTarMarr, "数据错误")
	if oTarMarr:IsInInviteSilenceMap(oRole:GetID()) then 
		oRole:Tips("对方婉拒了你的请求")
		local tRetMsg = {}
		tRetMsg.nTarRoleID = nTarID
		tRetMsg.bAgree = false
		oRole:SendMsg("MarriageAskRet", tRetMsg)
		return 
	end

	local fnConfirmCallback = function (tData)
		local bAgree = false
        if not tData then 
			oRole:Tips("对方婉拒了你的请求")
			return
		end
		if tData.nSelIdx == 1 then 
			oRole:Tips("对方婉拒了你的请求")
			if tData.nTypeParam and tData.nTypeParam > 0 then 
				oTarMarr:InsertInviteSilenceMap(oRole:GetID())
			end
		elseif tData.nSelIdx == 2 then  --确定
			bAgree = true
		end
		local tRetMsg = {}
		tRetMsg.nTarRoleID = nTarID
		tRetMsg.bAgree = bAgree
		oRole:SendMsg("MarriageAskRet", tRetMsg)
    end

    local sCont = string.format("%s 向你发出了结婚邀请，是否接受？", oRole:GetName())
    local tMsg = {sCont=sCont, tOption={"拒绝", "确定"}, nTimeOut=30, nType=3, nTypeParam=oRole:GetID()}
    goClientCall:CallWait("ConfirmRet", fnConfirmCallback, oTarRole, tMsg)
    oRole:Tips(string.format("已向 %s 发出了结婚邀请，正在等待回复", oTarRole:GetName()))
end

function CMarriageMgr:MarryPermitDataReq(oRole, nTarID)
	if not nTarID or nTarID <= 0 or oRole:GetID() == nTarID then 
		oRole:Tips("错误数据")
		return 
	end
	local oTarRole = goGPlayerMgr:GetRoleByID(nTarID)
	if not oTarRole then 
		oRole:Tips("对方已离线")
		return 
	end
	local nRoleID = oRole:GetID()
	local bCanMarry, tCheckList = self:CheckMarry(nRoleID, nTarID)
	local tRetData = {}
	tRetData.bTeam = tCheckList.bTeamAndGender
	tRetData.bLevel = tCheckList.bLevel
	tRetData.bFriend = tCheckList.bFriend
	tRetData.bMarriage = tCheckList.bMarriageState
	tRetData.nTarRoleID = nTarID
	oRole:SendMsg("MarryPermitDataRet", tRetData)
end

--处理离婚
function CMarriageMgr:DealDivorce(nCoupleID)
	local oCouple = self:GetCouple(nCoupleID)
	if not oCouple then
		return
	end
	local nHusbandID = oCouple:GetHusbandID()
	local nWifeID = oCouple:GetWifeID()
	local oHusbandMarr = self:GetRoleMarriage(nHusbandID)
	local oWifeMarr = self:GetRoleMarriage(nWifeID)
	local nTimeStamp = os.time()
	local oDB = goDBMgr:GetSSDB(gnServerID, "global", GF.GetServiceID())
	oDB:HDel(gtDBDef.sMarriageCoupleDB, nCoupleID)
	self.m_tRoleCoupleMap[nHusbandID] = nil
	self.m_tRoleCoupleMap[nWifeID] = nil
	self.m_tCoupleMap[nCoupleID] = nil	
	oHusbandMarr:OnDivorce(nWifeID, nTimeStamp)
	oWifeMarr:OnDivorce(nHusbandID, nTimeStamp)

	--处理好友度
	local oHusbandFriend = goFriendMgr:GetFriend(nHusbandID, nWifeID)
	local oWifeFriend = goFriendMgr:GetFriend(nWifeID, nHusbandID)
	-- assert(oHusbandFriend and oWifeFriend, "好友关系错误")
	if oHusbandFriend then 
		oHusbandFriend:AddDegrees(-1000, "离婚")
	end
	if oWifeFriend then 
		oWifeFriend:AddDegrees(-1000, "离婚")
	end

	self:MarkDirty(true)
	self:SyncLogicCache(nHusbandID)
	self:SyncLogicCache(nWifeID)
end

function CMarriageMgr:DivorcePermitDataReq(oRole)
	--[[
	//离婚条件检查响应
	message DivorcePermitDataRet
	{
		required bool bTimeLimit = 1;       //是否满足结婚7天以上
	}
	]]
	local nRoleID = oRole:GetID()
	local oCouple = self:GetCoupleByRoleID(nRoleID)
	if not oCouple then
		oRole:Tips("当前未婚！")
		return
	end

	local tRetData = {}
	tRetData.bTimeLimit = false
	local nMarryStamp = oCouple:GetMarriageStamp()
	local nCurTime = os.time()
	if nCurTime - nMarryStamp >= (7*24*3600) then
		tRetData.bTimeLimit = true
	end
	oRole:SendMsg("DivorcePermitDataRet", tRetData)
end

--离婚请求
function CMarriageMgr:DivorceReq(oRole)
	local nRoleID = oRole:GetID()
	local oCouple = self:GetCoupleByRoleID(nRoleID)
	if not oCouple then
		oRole:Tips("当前未婚状态")
		return
	end

	if oCouple:GetState() == gtCoupleState.eDivorcing then
		local nDivorceCountdown = oCouple:GetDivorceCountdown()
		if nDivorceCountdown > 0 then
			nDivorceCountdown = nDivorceCountdown + 60
			local sTipsContent = string.format("距离月老审核还有%d天%d小时", 
				math.floor(nDivorceCountdown/(24*3600)), 
				math.floor(nDivorceCountdown/3600))
			oRole:Tips(sTipsContent)
		end
		return
	end

	if os.time() - oCouple:GetMarriageStamp() < (7 * 24 * 3600) then 
		oRole:Tips("向来情深，奈何缘浅。成亲尚不足七日，再好好珍惜一下")
		return 
	end

	local tCost = {{nType = gtItemType.eCurr, nID = gtCurrType.eYinBi, nNum = 1000000},}

	local fnConfirmCallback = function (tData)
		if tData.nSelIdx == 1 then  --取消
			return
		elseif tData.nSelIdx == 2 then  --确定
			local fnSubItemCallback = function (bRet)
				if not bRet then
					return
				end
				if oCouple:GetState() ~= gtCoupleState.eNormal then --多次点击，rpc调用期间，状态发生变化
					return
				end
				oCouple:SetState(gtCoupleState.eDivorcing)
				oCouple.m_nDivorceRole = nRoleID
				oCouple.m_nDivorceStamp = os.time()
				oCouple:MarkDirty(true)
				local nCoupleID = oCouple:GetID()
				self.m_tDivorceList[nCoupleID] = nCoupleID
		
				--发送邮件通知配偶
				local nSpouseID = oCouple:GetSpouseID(nRoleID)
				local oSpouse = goGPlayerMgr:GetRoleByID(nSpouseID)
				if oSpouse then  --可能删号了
					local sMailTitle = "强制离婚通知"
					local sMailContent = string.format("你的伴侣%s已经申请了强制离婚。如果你还想挽回这段感情，请尽快找你的伴侣谈一谈吧。三天之内都可以终止强制离婚的哦",
						oRole:GetName())
					oSpouse:SendSysMail(sMailTitle, sMailContent, {})
				end
				oRole:Tips("你的离婚申请已经递交给月老，你还有3天的冷静期可以随时找我终止离婚申请哦")
			end
			oRole:SubItemShowNotEnoughTips(tCost, "强制离婚", true, false, fnSubItemCallback)
		end
	end

	local sCont = "强制离婚有3天的冷静期，你可以随时找我终止离婚。需要先缴纳100万银币的申请费。确定继续？"
	local tMsg = {sCont=sCont, tOption={"取消", "确定"}, nTimeOut=60}
	goClientCall:CallWait("ConfirmRet", fnConfirmCallback, oRole, tMsg)
	
	-- local fnSubItemCallback = function (bRet)
	-- 	if not bRet then
	-- 		return
	-- 	end
	-- 	if oCouple:GetState() ~= gtCoupleState.eNormal then --多次点击，rpc调用期间，状态发生变化
	-- 		return
	-- 	end
	-- 	oCouple:SetState(gtCoupleState.eDivorcing)
	-- 	oCouple.m_nDivorceRole = nRoleID
	-- 	oCouple.m_nDivorceStamp = os.time()
	-- 	oCouple:MarkDirty(true)
	-- 	local nCoupleID = oCouple:GetID()
	-- 	self.m_tDivorceList[nCoupleID] = nCoupleID

	-- 	--发送邮件通知配偶
	-- 	local nSpouseID = oCouple:GetSpouseID(nRoleID)
	-- 	local oSpouse = goGPlayerMgr:GetRoleByID(nSpouseID)
	-- 	if oSpouse then  --可能删号了
	-- 		local sMailTitle = "强制离婚通知"
	-- 		local sMailContent = string.format("你的伴侣%s已经申请了强制离婚。如果你还想挽回这段感情，请尽快找你的伴侣谈一谈吧。三天之类都可以终止强制离婚的哦",
	-- 			oRole:GetName())
	-- 		oSpouse:SendSysMail(sMailTitle, sMailContent, {})
	-- 	end
	-- 	oRole:Tips("你的离婚申请已经递交给月老，你还有3天的冷静期可以随时找我终止离婚申请哦")
	-- end
	-- oRole:SubItemShowNotEnoughTips(tCost, "强制离婚", true, false, fnSubItemCallback)

end

function CMarriageMgr:DivorceCancelReq(oRole)
	local nRoleID = oRole:GetID()
	local oCouple = self:GetCoupleByRoleID(nRoleID)
	if not oCouple then
		oRole:Tips("当前未婚状态")
		return
	end
	if oCouple:GetState() ~= gtCoupleState.eDivorcing then
		oRole:Tips("当前未处于离婚状态")
		return
	end
	if oCouple:GetDivorceRole() ~= nRoleID then
		oRole:Tips("不是本人申请，无法取消")
		return
	end
	oCouple:SetState(gtCoupleState.eNormal)
	oCouple.m_nDivorceRole = 0
	oCouple.m_nDivorceStamp = 0
	oCouple:MarkDirty(true)

	local nSpouseID = oCouple:GetSpouseID(nRoleID)
	local oSpouse = goGPlayerMgr:GetRoleByID(nSpouseID)
	if oSpouse then
		local sTipsContent = string.format("你和%s的离婚申请已经取消，爱情峰回路转，幸福就在前方！", oSpouse:GetName())
		oRole:Tips(sTipsContent)
		local sMailTitle = "离婚申请取消"
		local sMailContent = "您的伴侣取消了离婚申请，看来这段婚姻尚有转机，希望你们好好经营这段感情。"
		oSpouse:SendSysMail(sMailTitle, sMailContent, {})
	else
		oRole:Tips("离婚申请已经取消")
	end
	local nCoupleID = oCouple:GetID()
	self.m_tDivorceList[nCoupleID] = nil
end

function CMarriageMgr:PalanquinStartNotice(nRoleID)
	if not nRoleID or nRoleID <= 0 then 
		return 
	end
	-- if not tCouple or not tCouple.nHusband or not tCouple.nWife then 
	-- 	return 
	-- end
	local oCouple = self:GetCoupleByRoleID(nRoleID)
	if not oCouple then 
		return 
	end
	local nHusbandID = oCouple:GetHusbandID()
	local nWifeID = oCouple:GetWifeID()
	assert(nHusbandID > 0 and nWifeID > 0)
	local oHusband = goGPlayerMgr:GetRoleByID(nHusbandID)
	local oWife = goGPlayerMgr:GetRoleByID(nWifeID) 
	assert(oHusband and oWife)

	local sBroadcastContent = 
	string.format("%s和%s正在使用花轿游览三生殿！游览途中可能会赠送宾客小礼物哦！快去围观吧！", 
		oHusband:GetFormattedName(), oWife:GetFormattedName())
	GF.SendNotice(0, sBroadcastContent)
	--邮件？？不需要了吧？？
end

--结婚邀请
function CMarriageMgr:InviteTalkReq(oRole)
	if not oRole then return end
	if not self:IsSysOpen(oRole, true) then 
		return 
	end
    local oRoleData = self:GetRoleMarriage(oRole:GetID())
    assert(oRoleData)
    local nCurTime = os.time()
    local nPasTime = nCurTime - (oRoleData.m_nLastInviteTalkStamp or 0)
    if nPasTime < 60 then 
        oRole:Tips(string.format("操作频繁，请%s秒后再试", 60 - nPasTime))
        return
	end

	local fnQueryCallback = function(sPreStr)
		if not sPreStr then 
			return 
		end
		local nGender = oRole:GetGender()
		local tTalkConf = nil
		if 1 == nGender then 
			tTalkConf = ctTalkConf["malemarriageinvite"] 
		else 
			tTalkConf = ctTalkConf["femalemarriageinvite"]
		end
		assert(tTalkConf)
		local sContentTemplate = tTalkConf.tContentList[math.random(#tTalkConf.tContentList)][1]
		local nTeamID = goTeamMgr:GetRoleTeamID(oRole:GetID())
		local sContent = string.format(sContentTemplate, oRole:GetID())
		
		oRoleData.m_nLastInviteTalkStamp = nCurTime
		local sMsgContent = sPreStr..sContent
        GF.SendWorldTalk(oRole:GetID(), sMsgContent, true)
		oRole:Tips("消息发布成功")
		goRemoteCall:Call("OnInviteMarry", oRole:GetStayServer(), oRole:GetLogic(), oRole:GetSession(), oRole:GetID(), {})
    end
    oRole:QueryRelationshipInvitePreStr(fnQueryCallback)
end

function CMarriageMgr:OnRoleOnline(oRole)
	local nRoleID = oRole:GetID()
	if oRole:IsRobot() then 
		return 
	end
	if not self:GetRoleMarriage(nRoleID) then
		self:InsertRoleMarriage(nRoleID)
	end
	local oRoleMarr = self:GetRoleMarriage(oRole:GetID())
	oRoleMarr:CleanInviteSilenceMap()
	self:SyncLogicCache(nRoleID)
end

function CMarriageMgr:OnRoleOffline(oRole) 
	local oRoleMarr = self:GetRoleMarriage(oRole:GetID())
	if not oRoleMarr then 
		return 
	end
	oRoleMarr:CleanInviteSilenceMap()
end

function CMarriageMgr:SyncLogicCache(nRoleID, nSrcServer, nSrcService, nTarSession)
	assert(nRoleID and nRoleID >  0)
    local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then 
        return 
    end
    nSrcServer = nSrcServer or oRole:GetStayServer()
    nSrcService = nSrcService or oRole:GetLogic()
    nTarSession = nTarSession or oRole:GetSession()

    local oRoleMarriage = self:GetRoleMarriage(nRoleID)
    if not oRoleMarriage then
        return
	end
	local oCouple = self:GetCoupleByRoleID(nRoleID)
    local tData = {}
	tData.nSpouseID = oRoleMarriage:GetSpouse()
	if tData.nSpouseID > 0 then 
		local oRoleSpouse = goGPlayerMgr:GetRoleByID(tData.nSpouseID)
		if oRoleSpouse then 
			tData.sSpouseName = oRoleSpouse:GetName()
		end
	end
	tData.nTimeStamp = oCouple and oCouple:GetMarriageStamp() or 0
    goRemoteCall:Call("RoleSpouseUpdateReq", nSrcServer, nSrcService, nTarSession, nRoleID, tData)
end

function CMarriageMgr:GetSpouse(nRoleID)
	local oCouple = self:GetCoupleByRoleID(nRoleID)
	if not oCouple then 
		return 0
	end
	return oCouple:GetSpouseID(nRoleID)
end

function CMarriageMgr:OnNameChange(oRole)
	local nRoleID = oRole:GetID()
	local oCouple = self:GetCoupleByRoleID(nRoleID)
	if not oCouple then 
		return 
	end
	local nSpouse = oCouple:GetSpouseID(nRoleID)
	assert(nSpouse > 0)
	local oRoleSpouse = goGPlayerMgr:GetRoleByID(nSpouse)
	if not nSpouse then 
		return 
	end
	--更新配偶的夫妻称号
	local nAppeID = gtAppellationIDDef.eHusband
	if oRoleSpouse:GetGender() ~= 1 then 
		nAppeID = gtAppellationIDDef.eWife
	end
	oRoleSpouse:UpdateAppellation(nAppeID, {tNameParam={oRole:GetName()}}, nRoleID)
end

function CMarriageMgr:GetRoleInfoMarriageInfo(nRoleID)
	local tMarriageInfo = {}
	local oCouple = self:GetCoupleByRoleID(nRoleID)
	if oCouple then 
		local tSpouseInfo = {}
		local nSpouseID = oCouple:GetSpouseID(nRoleID)
		local oSpouse = goGPlayerMgr:GetRoleByID(nSpouseID)
		tSpouseInfo.nID = nSpouseID
		tSpouseInfo.sName  = oSpouse:GetName()
		tSpouseInfo.sModel = oSpouse:GetModel()
		tSpouseInfo.sHeader = oSpouse:GetHeader()
		tSpouseInfo.nGender = oSpouse:GetGender()
		tSpouseInfo.nSchool = oSpouse:GetSchool()
		tSpouseInfo.nLevel = oSpouse:GetLevel()

		tMarriageInfo.tSpouseData = tSpouseInfo
	end
	return tMarriageInfo
end



goMarriageMgr = goMarriageMgr or CMarriageMgr:new()

