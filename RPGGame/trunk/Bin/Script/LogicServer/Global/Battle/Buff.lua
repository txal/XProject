--BUFF
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CBuff:Ctor(oUnit, nID)
	self.m_oUnit = oUnit
	self.m_nID = nID
end

function CBuff:GetID() return self.m_nID end


