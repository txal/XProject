local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--玩家离线数据
function COfflineData:Ctor()
	self.m_nCharID = 0
	self.m_sName = ""
	self.m_nVIP = 0
	self.m_nWeiWang = 0 	--威望
	self.m_nChildNum = 0 	--子嗣数量
	self.m_nChapter = 0 	--已通关章节
	self.m_nRecharge = 0 	--总充值
	self.m_nLevel = 1
end

--加载数据
function COfflineData:LoadData(tData)
	self.m_nCharID = tData.m_nCharID
	self.m_sName = tData.m_sName
	self.m_nVIP = tData.m_nVIP
	self.m_nWeiWang = tData.m_nWeiWang or 0
	self.m_nChildNum = tData.m_nChildNum or 0
	self.m_nChapter = tData.m_nChapter or 0
	self.m_nRecharge = tData.m_nRecharge or self.m_nRecharge
	self.m_nLevel = tData.m_nLevel or self.m_nLevel
end

--打包数据
function COfflineData:SaveData()
	local tData = {}
	tData.m_nCharID = self.m_nCharID
	tData.m_sName = self.m_sName
	tData.m_nVIP = self.m_nVIP
	tData.m_nWeiWang = self.m_nWeiWang
	tData.m_nChildNum = self.m_nChildNum
	tData.m_nChapter = self.m_nChapter
	tData.m_nRecharge = self.m_nRecharge
	tData.m_nLevel = self.m_nLevel
	return tData
end

--取名字
function COfflineData:GetName() return self.m_sName end
--取角色名字
function COfflineData:GetCharID() return self.m_nCharID end
--VIP
function COfflineData:GetVIP() return self.m_nVIP end
--等级
function COfflineData:GetLevel() return self.m_nLevel end
--充值
function COfflineData:GetRecharge() return self.m_nRecharge end
