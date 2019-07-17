--NPC管理器
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CNpcMgr:Ctor()
	self.m_tNpcMap = {} 	--Npc映射{[编号]=对象,...}
	self.m_tDirtyNpcMap = {}
	self.m_nSaveTimer = nil

	self:Init()
end

function CNpcMgr:Init()
	for nID, tConf in pairs(ctNpcConf) do
		local cNpcClass = gtNpcClass[tConf.nType]
		if cNpcClass then
			self.m_tNpcMap[nID] = cNpcClass:new(nID)
		else
			if nID >=10801 and nID <= 10809 then
			else
				LuaTrace("Npc", nID, "未实现")
			end
		end
	end
end

function CNpcMgr:LoadData()
	local nServicID = gnServerID < gnWorldServerID and 20 or 110
	local oDB = goDBMgr:GetSSDB(gnServerID, "global", nServicID)

	for nID, oNpc in pairs(self.m_tNpcMap) do
		local sData = oDB:HGet(gtDBDef.sNpcMgrDB, tostring(nID))
		if sData ~= "" then
			local tData = cjson.decode(sData)
			if oNpc and oNpc.LoadData then
				oNpc:LoadData(tData)
			end
		end
	end

	self.m_nSaveTimer = GetGModule("TimerMgr"):Interval(gtGDef.tConst.nAutoSaveTime, function() self:SaveData() end)
end

function CNpcMgr:SaveData()
	local nServicID = gnServerID < gnWorldServerID and 20 or 110
	local oDB = goDBMgr:GetSSDB(gnServerID, "global", nServicID)
	for nNpcID, _ in pairs(self.m_tDirtyNpcMap) do
		local oNpc = self.m_tNpcMap[nNpcID]
		if oNpc and oNpc.SaveData then
			local tNpcData = oNpc:SaveData()
			oDB:HSet(gtDBDef.sNpcMgrDB, nNpcID, cjson.encode(tNpcData))
		end
	end
	self.m_tDirtyNpcMap = {}
end

function CNpcMgr:Release()
	for _, oNpc in pairs(self.m_tNpcMap) do
		oNpc:Release()
	end

	GetGModule("TimerMgr"):Clear(self.m_nSaveTimer)
	self.m_nSaveTimer = nil
	self:SaveData()
end

function CNpcMgr:GetNpc(nID)
	return self.m_tNpcMap[nID]
end

--角色上线
function CNpcMgr:Online(oRole)
	for nID, oNpc in pairs(self.m_tNpcMap) do
		oNpc:Online(oRole)
	end
end

--角色进入场景
function CNpcMgr:OnEnterScene(oRole)
	for nID, oNpc in pairs(self.m_tNpcMap) do
		oNpc:OnEnterScene(oRole)
	end
end

function CNpcMgr:MarkDirty(nNpcID, bDrity)
	bDirty = bDirty or nil
	self.m_tDirtyNpcMap[nNpcID] = bDrity
end
