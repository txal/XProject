--赠送系统
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

local nMaxSendProps = 5 --每日赠送道具最大个数
local nGiftBaoWuSunPrice = 3890	--赠送宝物道具需要累计充值的元宝数
-- local nWeddingCandyPropID = 11009
local nWeddingCandyLimitNum = 5

function CGiftMgr:Ctor()
	print("赠送系统***************")
	self.m_oGiftMap = {} 			--self.m_oGiftMap[角色ID] =赠送玩家对象
	self.m_nSaveTimer = nil
	self.m_nMinTimer = nil
	self.m_nDailyResetStamp = os.time()  --跨天重置时间戳
	self.m_tDirtyMap = {}
end

function CGiftMgr:RegAutoSave()
	self.m_nSaveTimer = GetGModule("TimerMgr"):Interval(gtGDef.tConst.nAutoSaveTime, function() self:SaveData() end)
end

function CGiftMgr:Init()
	self:RegAutoSave()
	self.m_nMinTimer = GetGModule("TimerMgr"):Interval(60, function() self:OnMinTimer() end)
	self:LoadData()
end

function CGiftMgr:OnMinTimer()
	local nTimeStamp = os.time()
	if not os.IsSameDay(nTimeStamp, self.m_nDailyResetStamp) then 
		for k, v in pairs(self.m_oGiftMap) do 
			v:DailyReset()
		end
		self.m_nDailyResetStamp = nTimeStamp
	end
end

function CGiftMgr:Release()
	if self.m_nMinTimer then
		GetGModule("TimerMgr"):Clear(self.m_nMinTimer)
		self.m_nMinTimer = nil
	end
	if self.m_nSaveTimer then 
		GetGModule("TimerMgr"):Clear(self.m_nSaveTimer)
		self.m_nSaveTimer = nil
	end
end

function CGiftMgr:SaveData()	
	local oDB = goDBMgr:GetGameDB(gnServerID, "global", CUtil:GetServiceID())
	local tSysData = {}
	tSysData.m_nDailyResetStamp = self.m_nDailyResetStamp
	oDB:HSet(gtDBDef.sGiftDB, "sysdata", cseri.encode(tSysData))

	for nRoleID, v in pairs(self.m_tDirtyMap) do 
		local oGift = self.m_oGiftMap[nRoleID]
		local tData = oGift:SaveData()
		if tData then 
			oDB:HSet(gtDBDef.sRoleGiftDB, nRoleID, cseri.encode(tData))
			oGift:MarkDirty(false)
		end
	end
	self.m_tDirtyMap = {}
end

function CGiftMgr:LoadData()
	local oDB = goDBMgr:GetGameDB(gnServerID, "global", CUtil:GetServiceID())

	local sSysData = oDB:HGet(gtDBDef.sGiftDB, "sysdata")
	if sSysData ~= "" then
		local tSysData = cseri.decode(sSysData)
		self.m_nDailyResetStamp = tSysData.m_nDailyResetStamp or self.m_nDailyResetStamp
	end

	local tKeys = oDB:HKeys(gtDBDef.sRoleGiftDB)
	for _, sRoleID in ipairs(tKeys) do
		local sRoleData = oDB:HGet(gtDBDef.sRoleGiftDB, sRoleID)
		local tRoleData = cseri.decode(sRoleData)
		local nRoleID = tRoleData.m_nRoleID
		local oGift = CGift:new(self, nRoleID)
		oGift:LoadData(tRoleData)
		self.m_oGiftMap[nRoleID] = oGift
	end
end

function CGiftMgr:IsDirty() return self.m_bDirty end
function CGiftMgr:MarkDirty(bDirty) self.m_bDirty = bDirty end

function CGiftMgr:GetGiftTypeByPropData(tItem)
	assert(tItem and tItem.nPropID)
	local tPropConf = ctPropConf[tItem.nPropID]
	assert(tPropConf)
	if tPropConf.nType == 32 or tPropConf.nType == 33 then 
		return gtSendPropType.eTreasure
	elseif tPropConf.nType == 15 then 
		return gtSendPropType.eFlower
	else
		return gtSendPropType.eProp
	end
end

function CGiftMgr:CheckGiftListType(tItemList, nType)
	assert(tItemList and nType)
	for k, v in pairs(tItemList) do 
		if self:GetGiftTypeByPropData(v) ~= nType then 
			return false
		end
	end
	return true
end

function CGiftMgr:IsGiftTypeValid(nType)
	for k, v in pairs(gtSendPropType) do 
		if v == nType then 
			return true
		end
	end
	return false
end

--是否有赠送数量限制
function CGiftMgr:IsPropNumLimit(nID)
	assert(nID and nID > 0)
	local tMarketConf = ctBourseItem[nID]  --在摆摊交易表中的，则有赠送限制
	if tMarketConf then 
		return true
	end
	return false
end

--是否需要计数统计  --TODO 全部挪到一张控制表中
function CGiftMgr:IsPropCount(nID)
	if nID == gnWeddingCandyPropID then 
		return true
	end
	return false
end

function CGiftMgr:CheckPropSendLimit(nID)
	local tPropConf = ctPropConf[nID]
	if not tPropConf or not tPropConf.bGiftable then 
		return false
	end
	return true
end

--赠送不同类型物品进行不同检测
function CGiftMgr:CheckSendType(oRole, nTarRoleID, tItemList, nType)
	local nRoleID = oRole:GetID()
	if not self:CheckGiftListType(tItemList, nType) then 
		oRole:Tips("礼物类型错误")
		return
	end
	if nType == gtSendPropType.eTreasure then
		local fnGetTotalMoneyReqCallBack = function (nTotalMoney)
			if nTotalMoney and nTotalMoney < nGiftBaoWuSunPrice then
				return oRole:Tips(string.format("需要累积充值达到3890元宝才可以赠送宝物。您当前累积充值%d元宝，还需%d元宝", nTotalMoney, nGiftBaoWuSunPrice - nTotalMoney))
			end
			self:SendPropHandles(oRole, nTarRoleID, tItemList, nType)
		end
		Network:RMCall("GetTotalMoneyReq", fnGetTotalMoneyReqCallBack,oRole:GetStayServer(), oRole:GetLogic(), oRole:GetSession(), oRole:GetID())
	elseif nType == gtSendPropType.eProp then
		-- local oGift = self.m_oGiftMap[nRoleID]
		-- local nGiftNum = oGift:GetGiftNum(nTarRoleID) + self:GetSendNum(tItemList)
		-- if nGiftNum > nMaxSendProps then
		-- 	oRole:Tips(string.format("每天只能赠送%d个物品哦", nMaxSendProps))
		-- 	return
		-- end
		self:SendPropHandles(oRole, nTarRoleID, tItemList, nType)
	elseif nType == gtSendPropType.eFlower then
		self:SendPropHandles(oRole, nTarRoleID, tItemList, nType)
	end
end

-- function CGiftMgr:GetSendNum(tItemList)
-- 	local  nSendNum = 0
-- 	for k , tItem in pairs(tItemList) do
-- 		nSendNum = nSendNum + tItem.nSendNum
-- 	end
-- 	return nSendNum
-- end

--赠送道具
--tItemList{{nPropID, nSendNum, nGrid}, ...}
function CGiftMgr:GiftPropReq(oRole, nTarRoleID, tItemList, nType)
	--assert(nSendNum > 0, "参数错误")
	assert(oRole and nTarRoleID and tItemList and nType)
	print("tItemList", tItemList)
	local oTarRole = goGPlayerMgr:GetRoleByID(nTarRoleID)
	if not oTarRole then 
		return oRole:Tips("目标玩家不存在")
	end
	if not oTarRole:IsOnline() then
		return oRole:Tips("好友不在线，不能赠送物品")
	end

	if #tItemList < 1 then 
		return oRole:Tips("请选择需要赠送的物品")
	end
	if #tItemList > 20 then 
		return oRole:Tips("超过单次赠送物品上限")
	end
	--排重，相同格子
	local tTempItemMap = {}
	for k, tItem in ipairs(tItemList) do 
		if tItem.nPropID <= 0 or tItem.nGrid <= 0 or not ctPropConf[tItem.nPropID] then 
			return oRole:Tips("非法数据")
		end
		if tTempItemMap[tItem.nGrid] then 
			return oRole:Tips("非法数据")
		end
		tTempItemMap[tItem.nGrid] = tItem
	end

	local nRoleID = oRole:GetID()
	if nRoleID == nTarRoleID then
		return
	end
	if not self:IsGiftTypeValid(nType) then 
		return oRole:Tips("非法类型")
	end

	local oFriend = goFriendMgr:GetFriend(nRoleID, nTarRoleID)
	local oTarFriend = goFriendMgr:GetFriend(nTarRoleID, nRoleID)
	if not oFriend or not oTarFriend then
		return oRole:Tips("需要彼此是好友关系才可以赠送哦")
	end

	for k, tItem in pairs(tItemList) do
		local tPropConf = ctPropConf[tItem.nPropID]
		if not tPropConf.bGiftable then
			return oRole:Tips(string.format("%s不能赠送", tPropConf.sName))
		end
	end

	local oGift = self.m_oGiftMap[nRoleID]
	local oTarGift = self.m_oGiftMap[nTarRoleID]
	assert(oGift and oTarGift)
	--喜糖需要修正到可赠送数量
	local nWeddingCandyNum = 0   --该次赠送，请求赠送的喜糖数量
	local nWeddingCandyRecordNum = oTarGift:GetGiftCount(gnWeddingCandyPropID)
	local nWeddingCandyAllowNum = math.max(0, nWeddingCandyLimitNum - nWeddingCandyRecordNum)
	local sWeddingCandyName = ctPropConf[gnWeddingCandyPropID].sName

	local nFixNum = 0
	for k, tItem in ipairs(tItemList) do 
		if tItem.nPropID == gnWeddingCandyPropID then 
			if nWeddingCandyAllowNum <= 0 then 
				return oRole:Tips(string.format("%s今天已获赠%d颗%s啦，也让别人沾沾喜气吧", 
					oTarRole:GetName(), nWeddingCandyLimitNum, sWeddingCandyName))
			end
			nWeddingCandyNum = nWeddingCandyNum + tItem.nSendNum
			if nFixNum + tItem.nSendNum > nWeddingCandyAllowNum then 
				tItem.nSendNum = nWeddingCandyAllowNum - nFixNum
				nFixNum = nWeddingCandyAllowNum
			else
				nFixNum = nFixNum + tItem.nSendNum
			end
		end
	end
	if nWeddingCandyNum > 0 and nWeddingCandyNum > nWeddingCandyAllowNum then 
		oRole:Tips(string.format("%s今天已获赠%d颗%s啦，最多送出%d颗", 
			oTarRole:GetName(), nWeddingCandyRecordNum, sWeddingCandyName, nWeddingCandyAllowNum))
	end
	--移除掉数量少于0的
	local tNewItemList = {}
	for k, tItem in ipairs(tItemList) do 
		if tItem.nSendNum > 0 then 
			table.insert(tNewItemList, tItem)
		end
	end
	if #tNewItemList < 1 then 
		return 
	end
	tItemList = tNewItemList --引用新的对象
	
	local nSendLimitNum = 0
	for k, tItem in pairs(tItemList) do 
		if self:IsPropNumLimit(tItem.nPropID) then 
			nSendLimitNum = nSendLimitNum + tItem.nSendNum
		end
	end
	if nSendLimitNum > 0 then 
		local nGiftNum = oGift:GetGiftNum(nTarRoleID) + nSendLimitNum
		if nGiftNum > nMaxSendProps then
			oRole:Tips(string.format("每天只能赠送%d个物品哦", nMaxSendProps))
			return
		end
	end
	self:CheckSendType(oRole, nTarRoleID, tItemList, nType)
end

--赠送道具处理
function CGiftMgr:SendPropHandles(oRole, nTarRoleID, tList, nType)
	local oTarRole = goGPlayerMgr:GetRoleByID(nTarRoleID)
	assert(oTarRole)
	local fnGetAccountStateCallBack = function(nAccountState)
		if nAccountState == gtAccountState.eLockAccount then
			return oRole:Tips("您被封号不能进行赠送")
		end
		local oGift = self.m_oGiftMap[oRole:GetID()]
		local oTarGift = self.m_oGiftMap[nTarRoleID]
		assert(oTarGift)
		local fnPropDataCallback = function(bRet, tPropDataList)
			if not bRet or #tPropDataList < 1 then 
				return 
			end
			local tPropNumCount = {}
			--合并相同ID道具数量记录
			for k, tPropData in ipairs(tPropDataList) do 
				tPropNumCount[tPropData.m_nID] = (tPropNumCount[tPropData.m_nID] or 0) + tPropData.m_nFold
				tPropData.m_bBind = true --所有道具设置为绑定的
			end

			local sPropNameList = nil
			for k, v in pairs(tPropNumCount) do 
				local tPropConf = ctPropConf[k]
				if tPropConf and tPropConf.sName then 
					if sPropNameList then 
						sPropNameList = sPropNameList.."、"..tPropConf.sName
					else
						sPropNameList = tPropConf.sName
					end
				end
			end
			
			if nType == gtSendPropType.eFlower then 
				local nTotalDegree = 0
				for k, tPropData in ipairs(tPropDataList) do 
					local tPropConf = ctPropConf[tPropData.m_nID]
					if tPropConf and tPropConf.eParam() > 0 then 
						nTotalDegree = nTotalDegree + tPropConf.eParam() * tPropData.m_nFold
					end
				end
				local oFriend = goFriendMgr:GetFriend(oRole:GetID(), nTarRoleID)
				local oTarFriend = goFriendMgr:GetFriend(nTarRoleID, oRole:GetID())
				oFriend:AddDegrees(nTotalDegree, "赠送鲜花类道具获得")
				oTarFriend:AddDegrees(nTotalDegree, "赠送鲜花类道具获得")

				local sRoleTipsTemplate = "你向%s赠送了%s，您与%s的亲密度增加了%d点"
				local sTarTipsTemplate = "%s向你赠送了%s，您与%s的亲密度增加了%d点"
				local sTipsContent = string.format(sRoleTipsTemplate, oTarRole:GetName(), sPropNameList, oTarRole:GetName(), nTotalDegree)
				oRole:Tips(sTipsContent)
				sTipsContent = string.format(sTarTipsTemplate, oRole:GetName(), sPropNameList, oRole:GetName(), nTotalDegree)
				oTarRole:Tips(sTipsContent)
			else
				local sMailTitle = string.format("%s赠送的物品", oRole:GetName())
				local sMailContent = string.format("%s向你赠送了%s, 请查收", oRole:GetName(), sPropNameList)
				CUtil:SendMail(oTarRole:GetServer(), sMailTitle, sMailContent, tPropDataList, oTarRole:GetID())

				local nWeddingCandyNum = tPropNumCount[gnWeddingCandyPropID] or 0
				if nWeddingCandyNum > 0 then 
					oRole:Tips(string.format("成功赠送%s %d个%s", oTarRole:GetFormattedName(), 
						nWeddingCandyNum, ctPropConf[gnWeddingCandyPropID].sName))
				end
			end

			local nDiamondRingID = 10050
			local nDiamondRingNum = tPropNumCount[nDiamondRingID] or 0
			if nDiamondRingNum > 0 then 
				local sBroadcastContent = 
					string.format("%s给%s赠送了%d个%s，此生心动，此时情动，许诺一世相伴！",
					oRole:GetFormattedName(), oTarRole:GetFormattedName(), nDiamondRingNum, 
					ctPropConf:GetFormattedName(nDiamondRingID))
				CUtil:SendNotice(0, sBroadcastContent)
			end

			oGift:AddRecord(oTarRole, tList)
			for k, v in pairs(tPropDataList) do 
				if self:IsPropNumLimit(v.m_nID) then 
					oGift:AddGiftNum(nTarRoleID,v.m_nFold)
				end
				if self:IsPropCount(v.m_nID) then 
					oTarGift:ItemGiftCount(v.m_nID, v.m_nFold)
				end
			end

			local oFriend = goFriendMgr:GetFriend(oRole:GetID(), nTarRoleID)
			local tMsg = {}
			tMsg.nTarRoleID = nTarRoleID
			tMsg.nDegrees = oFriend:GetDegrees()
			print("赠送消息返回", tMsg)
			oRole:SendMsg("GiftPropRet", tMsg)	
		end

		local tItemList = {}
		for k, v in pairs(tList) do 
			table.insert(tItemList, {nID = v.nPropID, nGrid = v.nGrid, nNum = v.nSendNum})
		end
		oRole:GetPropDataWithSub(tItemList, "赠送物品扣除", true, fnPropDataCallback)
	end

	Network:RMCall("AccountValueReq", fnGetAccountStateCallBack, oRole:GetServer(), goServerMgr:GetLoginService(oRole:GetServer()), oRole:GetSession(), oRole:GetAccountID(), "m_nAccountState")
end

--获取玩家赠送记录信息
function CGiftMgr:GiftGetRecordInfoReq(oRole)
	local oGift = self.m_oGiftMap[oRole:GetID()]
	--if not oGift then return end
	local tMsg = {}
	if oGift then
		tMsg.tGiftRecordList = oGift:GetRecordInfo()
	else
		tMsg.tGiftRecordList = {}
	end
	print("赠送记录信息-------", tMsg.tGiftRecordList)
	oRole:SendMsg("GiftGetRecordInfoRet", tMsg)
end

function CGiftMgr:Online(oRole)	
	local nRoleID = oRole:GetID()
	if not self.m_oGiftMap[nRoleID] then
		local oGift = CGift:new(self, nRoleID)
		if oGift then
			self.m_oGiftMap[nRoleID] = oGift
			oGift:MarkDirty(true)
		end
	end
end

function CGiftMgr:GiftGetSendNumReq(oRole, nRoleID)
	local oGift = self.m_oGiftMap[oRole:GetID()]
	print("oGift----", oGift)
	local tMsg = {}
	tMsg.nRoleID = nRoleID
	if oGift then
		tMsg.nSendNum = oGift:GetGiftNum(nRoleID)
	else
		tMsg.nSendNum = 0
	end
	print("获取玩家赠送信息=======", tMsg)
	oRole:SendMsg("GiftGetSendNumRet", tMsg)
end
