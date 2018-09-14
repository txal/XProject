local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--广东麻将模块
function CGame:Ctor(oPlayer)
	self.m_oPlayer = oPlayer
	self.m_tCurrGame = {nGameType=0, nRoomID=0, nDeskType=0}
	self.m_bDirty = false
end

function CGame:GetType()
	return gtModuleDef.tGame.nID, gtModuleDef.tGame.sName
end

function CGame:MarkDirty(bDirty)
	self.m_bDirty = bDirty
end

function CGame:LoadData(tData)
	--fix pd LOAD
end

function CGame:SaveData()
	if not self.m_bDirty then
		return
	end
	--fix pd SAVE
	self.m_bDirty = false
end

function CGame:SetCurrGame(nGameType, nRoomID, nDeskType)
	self.m_tCurrGame.nGameType = nGameType
	self.m_tCurrGame.nRoomID = nRoomID
	self.m_tCurrGame.nDeskType = nDeskType
	self:MarkDirty()
end

function CGame:GetCurrGame()
	return self.m_tCurrGame
end

function CGame:GetRoom()
	local oGameMgr = goGameMgr:GetGame(self.m_tCurrGame.nGameType)
	if not oGameMgr then
		return
	end
	return oGameMgr:GetRoom(self.m_tCurrGame.nRoomID)
end

function CGame:Offline()
	local oRoom = self:GetRoom()
	if oRoom then
		oRoom:Offline(self.m_oPlayer)
	end
end

function CGame:Online()
	local oRoom = self:GetRoom()
	if oRoom then
		oRoom:Online(self.m_oPlayer)
	end
end

--从数据库中加载数据
function CGame:DataFromDB(nCharID, sDataKey)
	local oGameDB = goDBMgr:GetSSDBByCharID(nCharID)
	local _, sModuleName = CGame:GetType()
	local sData = oGameDB:HGet(sModuleName, nCharID)
	if sData == "" then
		return
	end
	local tData = cjson.decode(sData)
	if sDataKey then
		return tData[sDataKey]
	end
	return tData
end

--写数据到数据库
function CGame:DataToDB(nCharID, sDataKey, xValue)
	local oGameDB = goDBMgr:GetSSDBByCharID(nCharID)
	local _, sModuleName = CGame:GetType()
	local sData = oGameDB:HGet(sModuleName, nCharID)
	local tData = sData == "" and {} or cjson.decode(sData)
	if tData[sDataKey] == xValue then
		return
	end
	tData[sDataKey] = xValue
	local sData = cjson.encode(tData)
	oGameDB:HSet(sModuleName, nCharID, sData)
	return tData
end