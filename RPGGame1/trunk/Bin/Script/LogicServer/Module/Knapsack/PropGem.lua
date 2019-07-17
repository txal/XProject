--宝石道具
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CPropGem:Ctor(oModule, nID, nGrid, bBind, tPropExt)
	CPropBase.Ctor(self,oModule, nID, nGrid, bBind, tPropExt) 

	local tConf = self:GetConf()
	self.m_nLevel = tConf.nLv						--等级
	self.m_nAttr = tConf.tAttr[1][2](self.m_nLevel)	--属性
end

function CPropGem:LoadData(tData)
	CPropBase.LoadData(self, tData)

	self.m_nLevel = tData.nLevel
	self.m_nAttr = tData.nAttr
end

function CPropGem:SaveData()
	local tData = CPropBase.SaveData(self)
	tData.nLevel = 	self.m_nLevel
	tData.nAttr = self.m_nAttr
	return tData
end


function CPropGem:GetConf() return assert(ctGemConf[self.m_nID]) end
function CPropGem:GetLevel() return self.m_nLevel end
function CPropGem:GetAttr() return self.m_nAttr end

function CPropGem:SetLevel(nLevel) self.m_nLevel = nLevel end
function CPropGem:SetAttr(nAttr) self.m_nAttr = nAttr end