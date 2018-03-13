--夫妻系统
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CSpouse:Ctor(oPlayer)
	self.m_oPlayer = oPlayer
end

function CSpouse:LoadData(tData)
	if not tData then
		return
	end
end

function CSpouse:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)

	local tData = {}
	return tData
end

function CSpouse:GetType()
	return gtModuleDef.tSpouse.nID, gtModuleDef.tSpouse.sName
end

function CSpouse:Online()
end

--取丈夫/妻子ID
function CSpouse:GetSpouse()
	return 0
end