--奖励记录管理
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

local nMaxRecordNum = 3			--最大显示数量
local nAutoSaveTick = 3*60

function CAwardRecordMgr:Ctor()
	self.m_bDirty = false
	self.m_nSaveTick = nil

	self.m_tAwardRecord = {} 		--奖励显示映射{[eid]={[id]={name, tAward},...},...}
	self.m_nVersion = 1 			--兼容旧数据
end

function CAwardRecordMgr:Init()
	self.m_tAwardRecord = {}
end

function CAwardRecordMgr:LoadData()
	local sData = goDBMgr:GetSSDB("Player"):HGet(gtDBDef.sAwardRecordDB, "data")
	if sData ~= "" then
		local tData = cjson.decode(sData)
		if self.m_nVersion == (tData.m_nVersion or 0) then
			self.m_tAwardRecord = tData.m_tAwardRecord
		end
	end
	--定时保存
	self:AutoSave()
end 

function CAwardRecordMgr:SaveData()
	print("CAwardRecordMgr:SaveData***")
	if not self:IsDirty() then return end
	self:MarkDirty(false)

	local tData = {}
	tData.m_tAwardRecord = self.m_tAwardRecord
	tData.m_nVersion = self.m_nVersion
	goDBMgr:GetSSDB("Player"):HSet(gtDBDef.sAwardRecordDB, "data", cjson.encode(tData))
end

function CAwardRecordMgr:MarkDirty(bDirty)
 	self.m_bDirty = bDirty
end

function CAwardRecordMgr:IsDirty()
	return self.m_bDirty
end

--释放
function CAwardRecordMgr:OnRelease()
    self:SaveData()
    goTimerMgr:Clear(self.m_nSaveTick)
	self.m_nSaveTick = nil
end

--自动保存
function CAwardRecordMgr:AutoSave()
	self.m_nSaveTick = goTimerMgr:Interval(nAutoSaveTick, function() self:SaveData() end)
end

--添加记录
function CAwardRecordMgr:AddRecord(nType, sRecord)
	if not sRecord or sRecord == "" then return end
	local tAwardRecord = self.m_tAwardRecord[nType] or {}
	table.insert(tAwardRecord, 1, sRecord)
	if #tAwardRecord > nMaxRecordNum then 
		table.remove(tAwardRecord)
	end 
	self.m_tAwardRecord[nType] = tAwardRecord
	self:MarkDirty(true)
end

--奖励记录请求
function CAwardRecordMgr:AwardRecordReq(oPlayer, nType)
	local tList = self.m_tAwardRecord[nType] or {}
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "AwardRecordRet", {tList=tList, nType=nType})
end 

goAwardRecordMgr = goAwardRecordMgr or CAwardRecordMgr:new()