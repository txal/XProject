--成就
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert



function CQuestion:Ctor(nKejuType,nID,nKey)
	self.m_nKejuType = nKejuType
	self.m_nID =nID
	self.m_nKey = nKey
	self.m_sContent = ""
	self.m_tAnswer = {}
	self.m_nRightAnswer = 0
	self.m_nAnswerHelp = 0
	self.m_tHelpData = {}
	self:Init()
end

--玩法类型
function CQuestion:GetKejuType()
	return self.m_nKejuType
end

--动态生成id
function CQuestion:GetQuestionID()
	return self.m_nID
end

--导表数据id
function CQuestion:GetQuestionKey()
	return self.m_nKey
end

function CQuestion:GetConfigData()
	return ctKejuQuestionConf[self.m_nKey]
end

function CQuestion:ReInit(nKejuType,nID,nKey)
	self.m_nKejuType = nKejuType
	self.m_nID = nID
	self.m_nKey = nKey
	self.m_sContent = ""
	self.m_tAnswer = {}
	self.m_nRightAnswer = 0
	self.m_nAnswerHelp = 0
	self.m_tHelpData = {}
	self:Init()
end

function CQuestion:Init()
	local tData = self:GetConfigData()
	local sTitle = tData["sQuestionDesc"]
	self.m_sContent = sTitle
	local sAnswerA = tData["sAnswerOfA"]
	local sAnswerB = tData["sAnswerOfB"]
	local sAnswerC = tData["sAnswerOfC"]
	local sAnswerD = tData["sAnswerOfD"]
	local tAnswer = {sAnswerA,sAnswerB,sAnswerC,sAnswerD}
	self.m_tAnswer = self:ShuffList(tAnswer)
	for nNo,sAnswer in pairs(self.m_tAnswer) do
		if sAnswer == sAnswerA then
			self.m_nRightAnswer = nNo
			break
		end
	end
end

function CQuestion:ShuffList(tAnswer)
	local nCnt = #tAnswer
	local tNoList = {}
	for i=1,nCnt do
		table.insert(tNoList,i)
	end
	local tRetAnswer = {}
	for i=1,nCnt do
		local nSelectPos = math.random(#tNoList)
		local nNo = table.remove(tNoList,nSelectPos)
		table.insert(tRetAnswer,tAnswer[nNo])
	end
	return tRetAnswer
end


function CQuestion:PackData()
	local tRet = {
		nQuestionID = self.m_nID,
		sTitle = self.m_sContent,
		tAnswer = self.m_tAnswer,
		nRightNo = self.m_nRightAnswer,
	}
	return tRet
end

function CQuestion:IsRight(nNo)
	if nNo == self.m_nRightAnswer then
		return true
	end
	return false
end

function CQuestion:GetTitle()
	return self.m_sContent
end

function CQuestion:GetAnswerList()
	return self.m_tAnswer
end

function CQuestion:SetAskHelp()
	self.m_nAnswerHelp = 1
end

function CQuestion:GetAskHelp()
	return self.m_nAnswerHelp
end

function CQuestion:AddHelpData(nRoleID,sRoleName,nAnswerNo)
	self.m_tHelpData[nRoleID] = {
		sName = sRoleName,
		nAnswerNo = nAnswerNo,
	}
end

function CQuestion:IsHelpQuestion(nRoleID)
	if self.m_tHelpData[nRoleID] then
		return true
	end
	return false
end

function CQuestion:PackHelpData()
	local tRet = {}
	for nRoleID,tHelpData in pairs(self.m_tHelpData) do
		table.insert(tRet,{
			nRoleID = nRoleID,
			sRoleName = tHelpData["sName"],
			nAnswerNo = tHelpData["nAnswerNo"]
		})
	end
	return tRet
end

function CQuestion:GetHelpAnswerNo(nRoleID)
	local tData = self.m_tHelpData[nRoleID] or {}
	return tData["nAnswerNo"] or 0
end