--排行榜第一个名变更的全服播报
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert
local nAutoSaveTime = 3*60

function CBroadcast:Ctor()
	self.m_tBroadcast = {}		--{[nRankingID] = nCharID,...}
	self.m_bDirty = false
	self.m_nSaveTick = nil
end

function CBroadcast:LoadData()
	local sData = goDBMgr:GetSSDB("Player"):HGet(gtDBDef.sBroadcastDB, "data")
	if sData == "" then return end
	local tData = cjson.decode(sData)
	self.m_tBroadcast = tData.m_tBroadcast
	self:AutoSave()
end

function CBroadcast:SaveData()
	if not self:IsDirty() then return end
	self:MarkDirty(false)

	local tData = {}
	tData.m_tBroadcast = self.m_tBroadcast
	goDBMgr:GetSSDB("Player"):HSet(gtDBDef.sBroadcastDB, "data", cjson.encode(tData))
end

function CBroadcast:MarkDirty(bDirty) self.m_bDirty = bDirty end
function CBroadcast:IsDirty() return self.m_bDirty end

--释放定时器
function CBroadcast:OnRelease()
	goTimerMgr:Clear(self.m_nSaveTick)
	self:SaveData()
end

--自动保存
function CBroadcast:AutoSave()
	self.m_nSaveTick = goTimerMgr:Interval(nAutoSaveTime, function() self:SaveData() end)
end

--排名变更
function CBroadcast:UpdateRanking(nID, oPlayer, nLastRank, nNowRank)
	if nLastRank == nNowRank then return end
	if oPlayer then 
		CmdNet.PBSrv2Clt(oPlayer:GetSession(), "UpdateRankingRet", {nID=nID, nLastRank=nLastRank, nNowRank=nNowRank})
	end
end

--记录播报数据
function CBroadcast:SetBroadcast(nRankingID, nType, nID, bOpen)
	assert(nType == 1 or nType == 2, "非法参数")
	if bOpen then 										--活动开启清空相关数据
		self.m_tBroadcast[nRankingID] = nil 
		self:MarkDirty(true)
	end 
	 
	if not nID then return end
	if self.m_tBroadcast[nRankingID] == nID then return end 
	local sName = ""

	if nType == 2 then 
		local oUnion = goUnionMgr:GetUnion(nID)
		sName = oUnion:GetName()
		self.m_tBroadcast[nRankingID] = nID			--联盟ID
	else 
		sName = goOfflineDataMgr:GetName(nID) 
		self.m_tBroadcast[nRankingID] = nID			--个人ID
	end
	local sContent = string.format(ctLang[nRankingID], sName, "第一名")
	CmdNet.PBSrv2All("BroadcastRet", {sContent=sContent, nID=nRankingID, nType=nType})
 	self:MarkDirty(true)
end

goBroadcast = goBroadcast or CBroadcast:new()
