--活动礼包
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--礼包活动奖励配置
local _TimeGiftConf = {}  --礼包奖励表
local function _PreProcessRoundsConf()
	for _, tConf in ipairs(ctTimeGiftConf) do
		_TimeGiftConf[tConf.nRounds] = _TimeGiftConf[tConf.nRounds] or {}
		table.insert(_TimeGiftConf[tConf.nRounds], tConf)
	end
end
_PreProcessRoundsConf()


function CTimeGift:Ctor(nID)
	CHDBase.Ctor(self, nID)     	--继承基类
	self.m_nRounds = 1
	self.m_nItemID = 0
end

function CTimeGift:LoadData()
	local sData = goDBMgr:GetSSDB("Player"):HGet(gtDBDef.sHuoDongDB, self:GetID())
	if sData ~= "" then
		local tData = cjson.decode(sData)
		self.m_nRounds = tData.m_nRounds or self.m_nRounds
		self.m_nItemID = tData.m_nItemID or self.m_nItemID
		CHDBase.LoadData(self, tData)
	end
end

function CTimeGift:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)

	local tData = CHDBase.SaveData(self)
	tData.m_nRounds = self.m_nRounds
	tData.m_nItemID = self.m_nItemID
	goDBMgr:GetSSDB("Player"):HSet(gtDBDef.sHuoDongDB, self:GetID(), cjson.encode(tData))
end

--开启活动
function CTimeGift:OpenAct(nStartTime, nEndTime, nAwardTime, nExtID, nExtID1)
	LuaTrace("开启礼包活动", nStartTime, nEndTime, nAwardTime, nExtID, nExtID1)
	nExtID = nExtID or 1

	local bExist = false
	for k=1, #ctTimeGiftConf do 
		if ctTimeGiftConf[k].nRounds == nExtID then 
			bExist = true
			break
		end
	end
	assert(bExist, "礼包活动轮次错误")

	self.m_nRounds = nExtID
	self.m_nItemID = nExtID1
	CHDBase.OpenAct(self, nStartTime, nEndTime, nAwardTime)	
	self:MarkDirty(true)
end

--玩家上线
function CTimeGift:Online(oPlayer)
	self:SyncState(oPlayer)
end

--进入初始状态
function CTimeGift:OnStateInit()
	LuaTrace("活动:", self.m_nID, "进入初始状态")
	self:SyncState()
end

--进入活动状态
function CTimeGift:OnStateStart()
	LuaTrace("活动:", self.m_nID, "进入开始状态")
	self:SyncState()
end

--进入领奖状态
function CTimeGift:OnStateAward()
	LuaTrace("活动:", self.m_nID, "进入奖励状态")
	self:SyncState()
end

--进入关闭状态
function CTimeGift:OnStateClose()
	LuaTrace("活动:", self.m_nID, "进入关闭状态")
	self:SyncState()
end

--获取活动物品
function CTimeGift:GetActItem(oPlayer)
	local tList = {}
	for _, tConf in ipairs(_TimeGiftConf[self.m_nRounds]) do 
		local tInfo = {}
		for _, tAward in ipairs(tConf.tAward) do 
			local nID = tAward[2]
			if nID == -1 then
				nID = self.m_nItemID
			end
			table.insert(tInfo, {nType=tAward[1], nID=nID, nNum=tAward[3]})
		end
		table.insert(tList, {nID=tConf.nID, sName=tConf.sName, nYuanBao=tConf.nYuanBao, tAward=tInfo, nRounds=tConf.nRounds})
	end
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "TimeGiftGetActItemRet", {tList = tList})
end

--同步活动状态
function CTimeGift:SyncState(oPlayer)
	local nState = self:GetState()
	local nStateTime = self:GetStateTime()
	local nBeginTime, nEndTime = self:GetActTime()
	local tMsg = {nID=self:GetID(), nState=nState, nStateTime=nStateTime, nBeginTime=nBeginTime, nEndTime=nEndTime, nRounds=self.m_nRounds, nItemID=self.m_nItemID}
	--同步给指定玩家
	if oPlayer then
		CmdNet.PBSrv2Clt(oPlayer:GetSession(), "TimeGiftStateRet", tMsg)
	--全服广播
	else
		CmdNet.PBSrv2All("TimeGiftStateRet", tMsg) 
	end
end

--购买礼包
function CTimeGift:BuyReq(oPlayer, nID)
	if not self:IsOpen() then
		return oPlayer:Tips("今天没有活动哦，请娘娘稍待几日")
	end
	local tConf = ctTimeGiftConf[nID]
	if tConf.nRounds ~= self.m_nRounds then
		return oPlayer:Tips("物品轮次ID错误")
	end
	if oPlayer:GetYuanBao() < tConf.nYuanBao then
		return oPlayer:YBDlg()
	end
	oPlayer:SubItem(gtItemType.eCurr, gtCurrType.eYuanBao, tConf.nYuanBao, "商城-"..tConf.sName)
	
	for _, tItem in ipairs(tConf.tAward) do
		local nItemID = tItem[2]
		if nItemID == -1 then
			nItemID = self.m_nItemID
		end
		oPlayer:AddItem(tItem[1], nItemID, tItem[3], "购买活动礼包")
	end
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "TimeGiftBuyRet", {nID=nID, nItemID=self.m_nItemID})
end


















