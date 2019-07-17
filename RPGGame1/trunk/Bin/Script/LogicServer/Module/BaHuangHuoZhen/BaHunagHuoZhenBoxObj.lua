local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert
--宝箱对象
function CBaHuangHuoZhenBoxObj:Ctor(oRole, oModel, nBoxID, tBox)
	self.m_oRole = oRole
	self.m_oModel = oModel
	self.m_nBoxID = nBoxID
	self.m_nPropID, self.m_nPropNum = self:GetInitPropID(tBox)
	self.m_tRoleHelp = {}	--求助的玩家ID  self.m_tRoleHelp[nRoleID] = true
	self.m_nHelpTimes = 0	--求助的次数
	self.m_nBoxState = 0	--宝箱状态 0未完成,1完成,3求助
	self.m_nExp = 0			--修炼经验

end

function CBaHuangHuoZhenBoxObj:LoadData(tData)
	if not tData then return end
	self.m_nBoxID = tData.m_nBoxID
	self.m_tRoleHelp = tData.m_tRoleHelp
	self.m_nHelpTimes = tData.m_nHelpTimes
	self.m_nBoxState = tData.m_nBoxState
	self.m_nPropID = tData.m_nPropID
	self.m_nPropNum = tData.m_nPropNum
	self.m_nExp = tData.m_nExp or 0
end

function CBaHuangHuoZhenBoxObj:SaveData()
	local tData = {}
	tData.m_tRoleHelp = self.m_tRoleHelp
	tData.m_nBoxState = self.m_nBoxState
	tData.m_nHelpTimes = self.m_nHelpTimes
	tData.m_nBoxID = self.m_nBoxID
	tData.m_nPropID = self.m_nPropID
	tData.m_nPropNum = self.m_nPropNum
	tData.m_nExp = self.m_nExp
	return tData
end

function CBaHuangHuoZhenBoxObj:SetBoxState(nState)
	self.m_nBoxState = nState
end

function CBaHuangHuoZhenBoxObj:GetBoxState()
	return self.m_nBoxState
end

function CBaHuangHuoZhenBoxObj:SetHelpTimes(nTimes)
	self.m_nHelpTimes = self.m_nHelpTimes + (nTimes or 0)
end

function CBaHuangHuoZhenBoxObj:GetHelpTimes()
	return self.m_nHelpTimes
end

function CBaHuangHuoZhenBoxObj:SetRoleHelp(nRoleID)
	self.m_tRoleHelp[nRoleID] = true
end

function CBaHuangHuoZhenBoxObj:GetRoleHelp(nRoleID)
	return self.m_tRoleHelp[nRoleID]
end

function CBaHuangHuoZhenBoxObj:GetBoxID()
	return self.m_nBoxID
end

function CBaHuangHuoZhenBoxObj:GetInitPropID(tBox)
	--TODD如过子类道有，则使用子类道具，则使用父类道具
	-- if tBox.tSubPropID and tBox.tSubPropID[1][1] ~= 0 then
	-- 	return tBox.tSubPropID[math.random(1, #tBox.tSubPropID)][1], tBox.nNum
	-- elseif tBox.tSubPropID then
	-- 	return tBox.nID, tBox.nNum
	-- end
	if tBox.tSubPropID then
		return tBox.nID, tBox.nNum
	end
	return tBox.m_nPropID, tBox.m_nPropNum
end

function CBaHuangHuoZhenBoxObj:PracticeExpHandle(nPrice, oRole)
	if not nPrice then return oRole:Tips("摆摊价格错误") end
	local tProp = ctPropConf[self:GetPropID()]
	if not tProp then return oRole:Tips("道具错误") end
	local nExp = 0
	nExp = ctBaHuangHuoZhenComplex[1].eFnStall(nPrice)
	local nPracticeSkillID = oRole.m_oPractice:GetDefauID()
	local tPracticeSkill = oRole.m_oPractice:GetSkillInfo(nPracticeSkillID)
	local nSkillLevel = tPracticeSkill.nLevel
	local nSkillMaxLevel = oRole.m_oPractice:MaxLevel() 
	local nSkillDifferent = ctBaHuangHuoZhenComplex[1].nPracticeLevelDifferent
	if nSkillLevel < nSkillMaxLevel - nSkillDifferent then
		nExp = nExp + math.ceil(nExp * (ctBaHuangHuoZhenComplex[1].nSuperfluityExp/100))
	end
	self.m_nExp = nExp * self.m_nPropNum
	self.m_oModel:MarkDirty(true)
end

function CBaHuangHuoZhenBoxObj:GetPracticeExp()
	return self.m_nExp
end

function CBaHuangHuoZhenBoxObj:GetPropID()
	return self.m_nPropID
end

function CBaHuangHuoZhenBoxObj:SetPropID(nPropID)
	self.m_nPropID = nPropID
end

function CBaHuangHuoZhenBoxObj:SetPropNum(nNum)
	self.m_nPropNum = nNum
end

function CBaHuangHuoZhenBoxObj:GetPropNum()
	return self.m_nPropNum
end

function CBaHuangHuoZhenBoxObj:GetExp(nValue)
	return (nValue or 0)
end

function CBaHuangHuoZhenBoxObj:GetBoxInfo(oRole)
	local tBox = {}
	tBox.nBoxID = self.m_nBoxID
	tBox.nState = self.m_nBoxState
	tBox.nXiuLianExp = self.m_nExp
	tBox.nPropID = self.m_nPropID
	tBox.nPropNum = self.m_nPropNum
	return tBox
end