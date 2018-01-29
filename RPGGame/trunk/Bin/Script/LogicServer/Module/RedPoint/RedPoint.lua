--小红点标记
function CRedPoint:Ctor(oPlayer)
	self.m_oPlayer = oPlayer
	self.m_tRedPointMap = {}	--记录小红点的映射{[nID] = nFlag,...}
end

function CRedPoint:LoadData(tData)
	if not tData then return end
	for sID, nFlag in pairs(tData.m_tRedPointMap) do 
		self.m_tRedPointMap[tonumber(sID)] = nFlag
	end
end

function CRedPoint:SaveData()
	if not self:IsDirty() then return end
	self:MarkDirty(false)
	local tData = {}
	tData.m_tRedPointMap = self.m_tRedPointMap
	return tData
end

function CRedPoint:GetType()
	return gtModuleDef.tRedPoint.nID, gtModuleDef.tRedPoint.sName
end

--玩家上线
function CRedPoint:Online()
	self:SyncState()
end

--小红点处理:nFlag=0表示没有小红点
function CRedPoint:MarkRedPoint(nID, nFlag)
	if (self.m_tRedPointMap[nID] or 0) == nFlag then
		return 
	end
	self.m_tRedPointMap[nID] = nFlag
	self:MarkDirty(true)
	self:SyncState()
end	

--同步状态
function CRedPoint:SyncState()
	local tMsg = {tList={}}
	for nID, nFlag in pairs(self.m_tRedPointMap) do 
		local tInfo = {nID=nID, nFlag=nFlag}
		table.insert(tMsg.tList, tInfo)
	end
	-- print("CRedPoint:SyncState***", tMsg)
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "RedPointStateRet", tMsg)
end

--离线标记小红点
function CRedPoint:MarkRedPointOffline(nCharID, nID, nFlag)
	local _, sDBName = self:GetType()
    local sData = goDBMgr:GetSSDB("Player"):HGet(sDBName, nCharID)  
    local tData = sData == "" and {} or cjson.decode(sData)
    tData.m_tRedPointMap = tData.m_tRedPointMap or {}
    local sID = tostring(nID)
    if tData.m_tRedPointMap[sID] == nFlag then
    	return
    end
    tData.m_tRedPointMap[sID] = nFlag
    goDBMgr:GetSSDB("Player"):HSet(sDBName, nCharID, cjson.encode(tData))  
end

--离线标记小红点
function CRedPoint:MarkRedPointAnyway(nCharID, nID, nFlag)
	local oPlayer = goPlayerMgr:GetPlayerByCharID(nCharID)
	if oPlayer then
		oPlayer.m_oRedPoint:MarkRedPoint(nID, nFlag)
	else
		CRedPoint:MarkRedPointOffline(nCharID, nID, nFlag)
	end
end