--建筑基类
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CJZBase:Ctor(oModule, oPlayer, nSysID)
	self.m_oPlayer = oPlayer
	self.m_oModule = oModule
	self.m_nSysID = nSysID
	self.m_nLv = 1
end

function CJZBase:LoadData(tData)
	self.m_nSysID = tData.m_nSysID
	self.m_nLv = tData.m_nLv
end

function CJZBase:SaveData()
	local tData = {}
	tData.m_nSysID = self.m_nSysID
	tData.m_nLv = self.m_nLv
	return tData
end

function CJZBase:SysID() return self.m_nSysID end
function CJZBase:Lv() return self.m_nLv end
function CJZBase:Conf() return ctJianZhuConf[self.m_nSysID] end

function CJZBase:SetLv(nLv)
	self.m_nLv = nLv
	self.m_oModule:MarkDirty(true)
end

function CJZBase:AttrAdd()
	local tConf = self:Conf()
	if not tConf then
		return 1, 0
	end
	local tLvConf = ctJianZhuLvConf[self.m_nLv]
	local nAttrID, nAttrVal = tConf.nType, tLvConf.nLvAttr
	return nAttrID, nAttrVal
end
