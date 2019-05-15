--宠物对象
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CPetObj:Ctor(oModule)
	self.m_oModule = oModule
end

function CPetObj:LoadData(tData)
end

function CPetObj:SaveData()
	local tData = {}
	return tData
end
