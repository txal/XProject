--婚姻配偶关系
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert


gtCoupleState = 
{
	eNormal = 0,         --正常
	eDivorcing = 1,      --离婚中
}

function CCouple:Ctor(nID)
	assert(nID > 0, "参数错误")
	self.m_nID = nID             --婚姻ID
	--self.m_nCoupleNum = 0        --婚姻编号(目前是等于nID)
	self.m_nHusbandID = 0        --丈夫ID
	self.m_nWifeID = 0           --妻子ID
	self.m_nMarriageSate = 0     --婚姻状态  正常、强制离婚中
	self.m_nMarriageStamp = 0    --结婚时间戳

	self.m_nDivorceRole = 0      --发起离婚的角色、丈夫或妻子
	self.m_nDivorceStamp = 0

	self.m_bDirty = false
end

function CCouple:MarkDirty(bDirty) 
	self.m_bDirty = bDirty 
	if self.m_bDirty then
		goMarriageMgr.m_tCoupleSaveQueue:Push(self.m_nID, self)
	end
end
function CCouple:IsDirty() return self.m_bDirty end
function CCouple:GetID() return self.m_nID end
function CCouple:GetHusbandID() return self.m_nHusbandID end
function CCouple:GetWifeID() return self.m_nWifeID end
function CCouple:GetState() return self.m_nMarriageSate end
function CCouple:SetState(nState) self.m_nMarriageSate = nState end
function CCouple:GetMarriageStamp() return self.m_nMarriageStamp end
--function CCouple:GetCoupleNum() return self.m_nCoupleNum end
function CCouple:GetDivorceRole() return self.m_nDivorceRole end
function CCouple:GetDivorceStamp() return self.m_nDivorceStamp end
function CCouple:GetDivorceCountdown()
	if self:GetState() ~= gtCoupleState.eDivorcing then
		return 0
	end
	local nCountdown = 0
	local nCurStamp = os.time()
	local nDivorceStamp = self:GetDivorceStamp()
	local nTimeOut = nDivorceStamp + 3*24*3600
	if nCurStamp < nTimeOut then
		nCountdown = nTimeOut - nCurStamp
	end
	-- print(string.format(">>>>>> 离婚倒计时 %d <<<<<<", nCountdown))
	return nCountdown
end
function CCouple:SaveData()
	local tData = {}
	tData.nID = self.m_nID
	tData.nHusbandID = self.m_nHusbandID
	tData.nWifeID = self.m_nWifeID
	tData.nMarriageSate = self.m_nMarriageSate
	tData.nMarriageStamp = self.m_nMarriageStamp
	tData.nDivorceRole = self.m_nDivorceRole
	tData.nDivorceStamp = self.m_nDivorceStamp
	return tData
end

function CCouple:LoadData(tData)
	if not tData then
		return
	end
	--self.m_nID = tData.nID
	self.m_nHusbandID = tData.nHusbandID
	self.m_nWifeID = tData.nWifeID
	self.m_nMarriageSate = tData.nMarriageSate
	self.m_nMarriageStamp = tData.nMarriageStamp
	self.m_nDivorceRole = tData.nDivorceRole
	self.m_nDivorceStamp = tData.nDivorceStamp
end

function CCouple:GetHusbandID() return self.m_nHusbandID end
function CCouple:GetWifeID() return self.m_nWifeID end
function CCouple:IsHusband(nRoleID) return self.m_nHusbandID == nRoleID end
function CCouple:IsWife(nRoleID) return self.m_nWifeID == nRoleID end
function CCouple:GetSpouseID(nRoleID)
	assert(nRoleID)
	return (nRoleID == self.m_nHusbandID) and self.m_nWifeID or self.m_nHusbandID
end

