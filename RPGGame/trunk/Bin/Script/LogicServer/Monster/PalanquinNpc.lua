--花轿
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert


function CPalanquinNpc:Ctor(nObjID, nConfID)
	CPublicNpc.Ctor(self, nObjID, nConfID)
	self.m_nMonType = gtMonType.ePalanquin

	self.m_oRelationObj = nil
end

function CPalanquinNpc:SetRelationObj(oObj)
	self.m_oRelationObj = oObj
end

function CPalanquinNpc:GetRelationObj(oObj) return self.m_oRelationObj end

function CPalanquinNpc:GetViewData()
	local tData = CPublicNpc.GetViewData(self)
	local oRelationObj = self:GetRelationObj()
	if oRelationObj then 
		local nHusbandID = oRelationObj:GetHusbandID()
		local nWifeID = oRelationObj:GetWifeID()
		assert(nHusbandID > 0 and nWifeID > 0)
		local oHusband = goPlayerMgr:GetRoleByID(nHusbandID)
		local oWife = goPlayerMgr:GetRoleByID(nWifeID)
		assert(oHusband and oWife)
		tData.tPalanquin = {}
		tData.tPalanquin.tHusbandInfo = oHusband:GetViewData()
		tData.tPalanquin.tWifeInfo = oWife:GetViewData()
		tData.tPalanquin.nTime = oRelationObj:GetRunTime()
	end
	return tData
end
	
