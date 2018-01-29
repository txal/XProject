--成就系统
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--成就表预处理
local _AchievementsConf = {}
local function _PreProcessAchievementsConf()
	for _, tConf in ipairs(ctAchievementsConf) do 
		_AchievementsConf[tConf.nType] = _AchievementsConf[tConf.nType] or {}
		table.insert(_AchievementsConf[tConf.nType], tConf)
	end
end
_PreProcessAchievementsConf()

--成就状态
CAchievements.tState = {
	eInit = 0, 		--未完成
	eStart = 1, 	--进行中
	eAward = 2, 	--可领奖
	eFinish = 3, 	--已完成
}

function CAchievements:Ctor(oPlayer)
	self.m_oPlayer = oPlayer
	self.m_tAchievements = {} 	--成就映射{[type]={nCount=0, tState={[nID]=nState, ...}}, ...}
end

function CAchievements:LoadData(tData)
	if tData then 
		self.m_tAchievements = tData.m_tAchievements
	else
		self:MarkDirty(true)
	end
	self:Init()
end

function CAchievements:Init()
	for nType, tConfList in pairs(_AchievementsConf) do
		local tConf = tConfList[1]
		local nID = tConf.nID

		local tData = self.m_tAchievements[nType]
		if not tData or not tData.tState or not tData.nCount or not tData.tState[nID] or tData.tState[nID]==self.tState.eInit then
			self.m_tAchievements[nType] = {nCount=0, tState={[nID]=self.tState.eStart}}
			self:MarkDirty(true)
		end
	end
end

function CAchievements:SaveData()
	if not self:IsDirty() then
		return
	end 
	self:MarkDirty(false)

	local tData = {}
	tData.m_tAchievements = self.m_tAchievements
	return tData
end

function CAchievements:GetType()
	return gtModuleDef.tAchievements.nID, gtModuleDef.tAchievements.sName
end

function CAchievements:Online()
	self:InfoReq()
	self.m_bInit = true
end

--记录成就
function CAchievements:SetAchievement(nType, nVal, bSet)
	assert(nType and nVal, "参数错误")
	if not _AchievementsConf[nType] then
		return
	end

	local nCount = self.m_tAchievements[nType].nCount
	if bSet then 
		if nCount == nVal then 
			return 
		end
		self.m_tAchievements[nType].nCount = nVal
	else
		self.m_tAchievements[nType].nCount = nCount + nVal 
	end
	self:MarkDirty(true)

	if self.m_bInit then
		self:InfoReq(nType)
	end
end

--成就状态
function CAchievements:GetAchievementsState(nType, nID)
	local nTarget = ctAchievementsConf[nID].nTarget

	local tAchievements = self.m_tAchievements[nType]
	local nCount = tAchievements.nCount or 0
	local nState = tAchievements.tState[nID] or self.tState.eInit

	if nState == self.tState.eStart then
		if nCount >= nTarget then 
			nState = self.tState.eAward
			tAchievements.tState[nID] = nState
			self:MarkDirty(true)
		end
	end

	return nState, nCount
end

--取当前最小领奖数
function CAchievements:GetMin(nType)
	local nTarget, nAward, nGot = 0, 0, 0

	local nCount = self.m_tAchievements[nType].nCount
	local tAchievements = _AchievementsConf[nType]

	for k, tAchie in ipairs(tAchievements) do 	
		nTarget = tAchie.nTarget
		local nState = self:GetAchievementsState(nType, tAchie.nID)		
		if (nState == self.tState.eStart or nState == self.tState.eInit) and nCount < nTarget then
			break
		end 
		if nState == self.tState.eAward then
			nAward = nAward + 1
		end
		if nState == self.tState.eFinish then
			nGot = nGot + 1
		end
	end
	local nTotal = #tAchievements
	return nTarget, nAward, nGot, nTotal
end

--各项成就状态
function CAchievements:EachAchieStateReq(nType)
	local tList = {}
	for _, tConf in ipairs(_AchievementsConf[nType]) do 
		local nID = tConf.nID
		local nTarget = tConf.nTarget
		local nState, nCount = self:GetAchievementsState(nType, nID)

		local tAward = {}	
		for _, tItem in ipairs(tConf.tAward) do
			table.insert(tAward, {nType=tItem[1], nID=tItem[2], nNum=tItem[3]})
		end
		table.insert(tList, {nID=nID, nState=nState, tAward=tAward, nTarget=nTarget, nCount=nCount})
	end
	local tMsg = {tList=tList, nType=nType}
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "AchievementsStateRet", tMsg)
end

--成就界面
function CAchievements:InfoReq(nType)
	local function _GenInfo(nTarType)
		local tAchievements = self.m_tAchievements[nTarType] or {}
		local nCurrent = tAchievements.nCount or 0
		local nTarget, nAward, nGot, nTotal= self:GetMin(nTarType)
		local tInfo = {nType=nTarType, nCurrent=nCurrent, nTarget=nTarget, nAward=nAward, nGot=nGot, nTotal=nTotal}
		return tInfo
	end

	local tList = {}
	if nType then
		table.insert(tList, _GenInfo(nType))

	else
		for nType, tConf in pairs(_AchievementsConf) do
			table.insert(tList, _GenInfo(nType))	
		end

	end

	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "AchievementsInfoRet", {tList=tList})
end

--成就奖励
function CAchievements:AchievementsAwardReq(nType, nID)
	assert(_AchievementsConf[nType] and ctAchievementsConf[nID], "参数有误")

	local nState = self:GetAchievementsState(nType, nID)

	if nState == self.tState.eInit or nState == self.tState.eStart then
		return self.m_oPlayer:Tips("未达到领奖条件")
	end

	if nState == self.tState.eFinish then 
		return self.m_oPlayer:Tips("已领过奖励")
	end

	local tState = self.m_tAchievements[nType].tState
	tState[nID] = self.tState.eFinish
	self:MarkDirty(true)

	for k, tConf in ipairs(_AchievementsConf[nType]) do
		if tConf.nID == nID then
			local tNxtConf = _AchievementsConf[nType][k+1]
			if tNxtConf then
				tState[tNxtConf.nID] = self.tState.eStart
				self:MarkDirty(true)
				break
			end
		end
	end

	local tList = {}
	local tConf = ctAchievementsConf[nID]
	for _, tAward in ipairs(tConf.tAward) do 
		self.m_oPlayer:AddItem(tAward[1], tAward[2], tAward[3], "成就奖励")
		table.insert(tList, {nType=tAward[1], nID=tAward[2], nNum=tAward[3]})
	end

	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "AchievementsAwardRet", {tList=tList})
	self:EachAchieStateReq(nType)
	self:InfoReq(nType)
end