--零元购活动
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--奖励状态
CZeroYuan.tAwardState = 
{	eInit = 0,			--不能领取道具奖励
	eAwardItem = 1, 	--领取道具奖励
	eAwardYuanBao = 2, 	--领取元宝奖励
	eNoAwardYuanBao = 3,	--不可领取元宝奖励
	eAwardAll = 4,			--领取完所有奖励
}

local nMaxOpenDay = 7 --开服前几天

function CZeroYuan:Ctor(nID)
	CHDBase.Ctor(self, nID)     	--继承基类
	self:Init()
end

function CZeroYuan:Init()
	self.m_tRoleActData = {}	--玩家活动数据{[roleid] = {nID = {nState = 0}}  --活动期间消耗的元宝数, 奖励是否领取
	self:MarkDirty(true)
end

function CZeroYuan:LoadData()
	local oSSDB = goDBMgr:GetGameDB(gnServerID, "global", CUtil:GetServiceID())
	local sData = oSSDB:HGet(gtDBDef.sHuoDongDB, self:GetID())
	if sData == "" then return end

	local tData = cseri.decode(sData)
	CHDBase.LoadData(self, tData)
	self.m_tRoleActData = tData.m_tRoleActData or {}

end

function CZeroYuan:SaveData()
	if not self:IsDirty() then
		return
	end
	local tData = CHDBase.SaveData(self)
	tData.m_tRoleActData = self.m_tRoleActData
	local oSSDB = goDBMgr:GetGameDB(gnServerID, "global", CUtil:GetServiceID())
	oSSDB:HSet(gtDBDef.sHuoDongDB, self:GetID(), cseri.encode(tData))
	self:MarkDirty(false)
end

--开启活动
function CZeroYuan:OpenAct(nStartTime, nEndTime, nAwardTime, nExtID)
	LuaTrace("零元购活动", nStartTime, nEndTime, nAwardTime, nExtID)
	nExtID = math.max(1, nExtID or 1)
	self:MarkDirty(true)

	CHDBase.OpenAct(self, nStartTime, nEndTime, nAwardTime)	
end

function CZeroYuan:GetRounds()
	return self.m_nRounds
end

--玩家上线
function CZeroYuan:Online(oRole)
	self:SyncState(oRole)
end

--取奖励状态
function CZeroYuan:GetAwardState(nRoleID, nID)
	local tRoleActData = self.m_tRoleActData[nRoleID]
	if not tRoleActData then
		return false
	end
	return tRoleActData.bAwardState
end

function CZeroYuan:GetMaxOpenDay()
	local nMaxOpenDay = os.PassDay(self.m_nBegTime, self.m_nEndTime, 0)
	return nMaxOpenDay
end

function CZeroYuan:GetAwardDay()
	local nMaxOpenDay = self:GetMaxOpenDay()
	return nMaxOpenDay
end

--设置奖励状态
function CZeroYuan:SetAwardState(oRole, nState)
	local nRoleID = oRole:GetID()
	local tRoleActData = self.m_tRoleActData[nRoleID]
	if tRoleActData then
		if tRoleActData.bAwardState == 0 then
			tRoleActData.nAwardState = nState
		else
			tRoleActData.nYuanBaoState = nState
		end
		self:SyncState(oRole)
		self:InfoReq(oRole)
		self:MarkDirty(true)
	end
end

--获取开服天数
function CZeroYuan:GetOpenDays()
	local nOpenDay = goServerMgr:GetOpenDays(gnServerID)
	return nOpenDay
end

--进入初始状态
function CZeroYuan:OnStateInit()
	LuaTrace("活动:", self.m_nID, "进入初始状态")
	self:SyncState()
end

--进入活动状态
function CZeroYuan:OnStateStart()
	LuaTrace("活动:", self.m_nID, "进入开始状态")
	self:Init()
	self:SyncState()
end

--进入领奖状态
function CZeroYuan:OnStateAward()
	LuaTrace("活动:", self.m_nID, "进入奖励状态")
	self:SyncState()
end

--进入关闭状态
function CZeroYuan:OnStateClose()
	LuaTrace("活动:", self.m_nID, "进入关闭状态")
	self:SyncState()
	self:CheckAward()
end

--同步活动状态
function CZeroYuan:SyncState(oRole)
	-- 	--同步给指定玩家
	if oRole then
		self:SyncActState(oRole)
	--全服广播
	else
		local tSessionMap = goGPlayerMgr:GetRoleSSMap()
		for nSession, oTmpRole in pairs(tSessionMap) do
			self:SyncActState(oTmpRole)
		end
	end
end

--同步活动状态
function CZeroYuan:SyncActState(oRole)
	assert(oRole, "角色数据错误")
	local nState = self:GetActState(oRole)
	local nBeginTime, nEndTime, nStateTime = self:GetStateTime(oRole)
	if nState == CHDBase.tState.eClose then
		nBeginTime, nEndTime = goHDCircle:GetActNextOpenTime(self:GetID())
		if nBeginTime > 0 and nBeginTime > os.time() then
			assert(nEndTime>nBeginTime, "下次开启时间错误")
			nState = CHDBase.tState.eInit
			nStateTime = nEndTime - nBeginTime
		end
	end
	local tMsg = {
		nID = self:GetID(),
		nState = nState,
		nStateTime = nStateTime or 0,
		nBeginTime = nBeginTime or 0,
		nEndTime = nEndTime or 0,
		tActData = self:GetActInfo(oRole)
	}
	oRole:SendMsg("ZYActStateRet", tMsg)
end

function CZeroYuan:GetActStateTime(oRole)
	assert(oRole, "角色错误")
	local tRoleActData = self.m_tRoleActData[oRole:GetID()]
	local nBeginTime, nEndTime, nStateTime = self:GetStateTime()
	local nNowSec = os.time()
	if tRoleActData and nNowSec > self.m_nEndTime and nNowSec < self:GetAwardTime(oRole) + self.m_nEndTime then
		nStateTime = self:GetAwardTime(oRole) + self.m_nEndTime - nNowSec 
	end
	return nBeginTime, nEndTime, nStateTime
end

function CZeroYuan:GetActState(oRole)
	assert(oRole, "角色数据错误")
	local nState = self.m_nState
	if not self:IsOpen()  and self:IsActEnd(oRole) then
		nState = CHDBase.tState.eAward
	else
		if os.time() > self.m_nEndTime then
			nState = CHDBase.tState.eClose
		end
	end
	return nState
end

function CZeroYuan:IsActEnd(oRole)
	if not oRole then return end
	local tRoleActData = self.m_tRoleActData[oRole:GetID()]
	if tRoleActData and not self:IsOpen() then
		local nNowSec = os.time()
		local nAwardTime = self:GetAwardTime(oRole)
		if nNowSec < nAwardTime  then
			return true
		end
	else
		return false
	end
end

function CZeroYuan:GetAwardTime(oRole)
	local tRoleActData = self.m_tRoleActData[oRole:GetID()]
	assert(tRoleActData, "数据错误")
	local nTime = os.ZeroTime(self.m_nBegTime)
	local nMaxBuyTime = self:GetMaxBuy(oRole)
	local nSumDay = self:GetAwardDay() + (nMaxBuyTime or 0)
	local nAwardTime = nSumDay * 24 * 3600 + self.m_nBegTime - nTime + os.time()
	return nAwardTime
end

function CZeroYuan:GetMaxBuy(oRole)
	local nBuyTime = 0 
	local tRoleActData = self.m_tRoleActData[oRole:GetID()]
	for _, tActData in pairs(tRoleActData or {}) do
		local nBuyTime = tActData.nBuyTime
		if nBuyTime < tActData.nBuyTime then
			nBuyTime = tActData.nBuyTime
		end
	end
	return nBuyTime
end
--检测奖励
function CZeroYuan:CheckAward()
	local _SendAwrd = function (tItemList, oRole)
		local sCont = string.format("您在零元购活动中获得以下奖励，请查收。") 
		CUtil:SendMail(oRole:GetServer(), "零元购活动奖励", sCont, tItemList, oRole:GetID())
	end

	for nRoleID, tRoleActData in pairs(self.m_tRoleActData) do
		local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
		if oRole then
			for nID, tState in pairs(tRoleActData or {}) do
				local tActCfg = ctZeroYuanConf[nID]
				if tState.nAwardState == 0 then
					local tAddItem = tActCfg.tAward
					_SendAwrd(tAddItem, oRole)
				end
				if tState.nYuanBaoState == 0 then
					local tAddItem = tActCfg.tAwardYuanBao
					_SendAwrd(tAddItem, oRole)
				end
			end
		end
	end
	self:MarkDirty(true)
end


function CZeroYuan:GetActInfo(oRole)
	local tActList = {}
	local nOpenDay = self:GetOpenDays()
	local tRoleActData = self:GetRoleActData(oRole:GetID())
	local nAwardType = self:GetAwardDay()
	for nID, tAct in pairs(ctZeroYuanConf) do
		local bBuy = false
		local nAwrdState = 0
		local nDays  = 0
		if tRoleActData and tRoleActData[nID] then
			local tActData = tRoleActData[nID]
			bBuy = true
			if tActData.nAwardState == 0 then
				nAwrdState = CZeroYuan.tAwardState.eAwardItem
				if nOpenDay < nAwardType + tActData.nBuyTime then
					nDays = nAwardType + tActData.nBuyTime - nOpenDay
				end
			else
				if nOpenDay >= nAwardType + tActData.nBuyTime then
					nAwrdState = CZeroYuan.tAwardState.eAwardYuanBao
				else
					nAwrdState = CZeroYuan.tAwardState.eNoAwardYuanBao
					nDays = self:GetAwardDay() + tActData.nBuyTime - nOpenDay
				end
			end
			if tActData.nAwardState ~= 0 and tActData.nYuanBaoState ~= 0 then
				nAwrdState = CZeroYuan.tAwardState.eAwardAll
			end

		end
		table.insert(tActList, {nID = nID, bBuy = bBuy, nAwrdState = nAwrdState, nDays = nDays, sPower = tAct.sPower})
	end
	return tActList
end

function CZeroYuan:GetRoleActData(nRoleID)
	return self.m_tRoleActData[nRoleID]
end

--取信息
function CZeroYuan:InfoReq(oRole)
	if not self:IsAward() and not self:IsOpen() then
		return oRole:Tips("活动已经结束")
	end
	local tMsg = {}
	tMsg.tActData = self:GetActInfo(oRole)
	self:SyncState(oRole)
	oRole:SendMsg("ZYActInfoRet", tMsg)
	return tMsg
end

--领取奖励
function CZeroYuan:AwardReq(oRole, nID)
	if not oRole or not nID or nID < 1 then
		return 
	end
	local tActCfg = ctZeroYuanConf[nID]
	assert(tActCfg,"配置文件错误" .. nID)

	local tRoleActData = self.m_tRoleActData[oRole:GetID()]
	if not tRoleActData or not tRoleActData[nID] then
		return 
	end
	local nOpenDay = self:GetOpenDays()
	local nAwardType
	local tAddItem
	local tLoginList
	if tRoleActData[nID].nAwardState == 0 then
		tRoleActData[nID].nAwardState = 1
		tAddItem = self:PropCheck(tActCfg.tAward)
		tLoginList = tActCfg.tAward
	else
		if tRoleActData[nID].nYuanBaoState == 0 then
			if nOpenDay < self:GetAwardDay() + tRoleActData[nID].nBuyTime then
				return oRole:Tips(string.format("该奖励%d天后才能领取哦", self:GetAwardDay() + tRoleActData[nID].nBuyTime - nOpenDay))
			end
			tRoleActData[nID].nYuanBaoState = 1
			tAddItem = self:PropCheck(tActCfg.tAwardYuanBao)
			tLoginList = tActCfg.tAwardYuanBao
		else
			return oRole:Tips("奖励全部领完了哦")
		end
	end
	self:SyncState(oRole)
	self:MarkDirty(true)

	--系统频道
	local function _fnCheckSysTalk(tItemList)
		local tTalkConf = ctTalkConf["zerobuy"]
		if not tTalkConf then
			return
		end
		local sAward = ""
		for _, tItem in pairs(tItemList) do
			sAward = string.format("%s %s+%d", sAward, ctPropConf:PropName(tItem.nID), tItem.nNum)
		end
		CUtil:SendSystemTalk("系统", string.format(tTalkConf.sContent, oRole:GetName(), sAward))
	end

	oRole:AddItem(tAddItem, "零元购活动获得", function(bRet)
		if bRet then
			--日志
			goLogger:ActivityLog(oRole, self:GetID(), self:GetName(), {}, tLoginList)
			_fnCheckSysTalk(tAddItem)
		end
	end)
end

--购买活动资格请求
function CZeroYuan:BuyQualificattionsReq(oRole, nID)
	if not oRole or not nID or nID < 1 then
		return 
	end
	if not self:IsOpen() then
		return oRole:Tips("活动已经结束")
	end

	local tRoleActData =  self.m_tRoleActData[oRole:GetID()]
	if tRoleActData and tRoleActData[nID] then
		return oRole:Tips("你已经购买了哦")
	end
	local nOpenDay = self:GetOpenDays()
	local tActCfg = ctZeroYuanConf[nID]
	assert(tActCfg, "零元购活动配置错误")
	local tSubItem = self:PropCheck(tActCfg.tBuyCost)
	local fnSubCostCallBack = function (bRet)
		if not bRet then return end
		--同步活动状态信息
		if tRoleActData then
			tRoleActData[nID] = {nAwardState = 0, nYuanBaoState = 0, nBuyTime = nOpenDay}
		else
			self.m_tRoleActData[oRole:GetID()] = {[nID] = {nAwardState = 0, nYuanBaoState = 0, nBuyTime = nOpenDay}}
		end
		self:SyncState(oRole)
		self:MarkDirty(true)
		oRole:Tips("购买成功")
	end
	oRole:SubItem(tSubItem, "零元活动购买消耗", fnSubCostCallBack)
end

function CZeroYuan:PropCheck(tItemList)
	local tAddItem = {}
	for _, tItem in pairs(tItemList or {}) do
		local nID = tItem[1] == gtItemType.eCurr and tItem[4] or tItem[2]
		assert(tItem[1] >= 1 or ctPropConf[tItem[2]] or tItem[3] >= 1, "零元购活动购买配置错误")
		table.insert(tAddItem, {nType = tItem[1], nID = nID, nNum = tItem[3]})
	end
	assert(#tAddItem > 0, "零元购活动购买配置错误")
	return tAddItem
end

function CZeroYuan:GetOverActTime()
	local nMaxOverTime
	for nID, tActData in pairs(self.m_tRoleActData) do
		nMaxOverTime = tActData.nBuyTime
		if nMaxOverTime > tActData.nBuyTime then
			nMaxOverTime = tActData.nBuyTime
		end
	end
	return nMaxOverTime
end

function CZeroYuan:ClearRoleActData(oRole)
	if self.m_tRoleActData[oRole:GetID()] then
		self.m_tRoleActData[oRole:GetID()] = nil
		self:MarkDirty(true)
		self:SyncState(oRole)
	end
	oRole:Tips("清除数据成功")
end