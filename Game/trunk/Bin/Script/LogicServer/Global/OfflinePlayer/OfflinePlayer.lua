--离线玩家数据

function COfflinePlayer:Ctor()
	self.m_nCharID = ""
	self.m_sName = ""
	self.m_nRoleID = 0
	self.m_nLevel = 0
	self.m_nVIP = 0
end

--加载数据
function COfflinePlayer:LoadData(tData)
	self.m_nCharID = tData.nCharID
	self.m_sName = tData.sName
	self.m_nRoleID = tData.nRoleID
	self.m_nLevel = tData.nLevel
	self.m_nVIP = tData.nVIP
end

--打包数据
function COfflinePlayer:PackData()
	local tData = {}
	tData.nCharID = self.m_nCharID
	tData.sName = self.m_sName
	tData.nRoleID = self.m_nRoleID
	tData.nLevel = self.m_nLevel
	tData.nVIP = self.m_nVIP
	return tData
end
