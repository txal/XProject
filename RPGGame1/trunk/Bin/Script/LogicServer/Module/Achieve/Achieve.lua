--成就
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert



function CAchieve:Ctor(oRole)
    self.m_oRole = oRole
    self.m_bDirty = false
    self.m_oAchieve = {}		--成就对象 self.m_oAchieve[nID] = oAchieve
    self.m_tAchieveDegree = {}	--类型对应次数 self.m_tAchieveDegree[nType] = nAmount

    self.m_tAchieveEvent = {}	--事件对应成就id列表
    self.m_tTypeAchieve = {}	--成就类型对应id列表

    self:InitAchieveEvent()
    self.m_nLoginTime = 0		--登录成就时间
end

function CAchieve:LoadData(tData)
	tData = tData or {}
	local tAchieve = tData.m_oAchieve or {}
	for nAchieveID,tAchieveData in pairs(tAchieve) do
		self.m_oAchieve[nAchieveID] = self:LoadAchieve(nAchieveID,tAchieveData)
	end
	self.m_tAchieveDegree = tData.m_tAchieveDegree or self.m_tAchieveDegree
	self.m_nLoginTime = tData.m_nLoginTime or self.m_nLoginTime
end

function CAchieve:SaveData()
	if not self:IsDirty() then
        return
    end
    self:MarkDirty(false)
	local tData = {}
	tData.m_oAchieve = {}
	for nAchieveID,oAchieve in pairs(self.m_oAchieve) do
		tData.m_oAchieve[nAchieveID] = oAchieve:SaveData()
	end
	tData.m_tAchieveDegree = self.m_tAchieveDegree
	tData.m_nLoginTime = self.m_nLoginTime
	return tData
end

function CAchieve:GetType(oRole)
    return gtModuleDef.tAchieve.nID, gtModuleDef.tAchieve.sName
end

function CAchieve:CheckSysOpen(bTips)
	if not self.m_oRole.m_oSysOpen:IsSysOpen(50, bTips) then
		return
	end
	return true
end

function CAchieve:CreateAchieve(nID)
	local oAchieve = CAchieveObj:new(nID)
	if oAchieve then
		return oAchieve
	end
end

function CAchieve:LoadAchieve(nID,tData)
	local oAchieve = self:CreateAchieve(nID)
	if oAchieve then
		oAchieve:LoadData(tData)
	end
	return oAchieve
end

function CAchieve:GetAchieve(nID)
	return self.m_oAchieve[nID]
end

function CAchieve:Online()
    self:SyncAchieveList()
    self:DoLoginAchieve()
end

function CAchieve:MarkDirty(bDirty) self.m_bDirty = bDirty end
function CAchieve:IsDirty() return self.m_bDirty end

--成就监听事件
function CAchieve:InitAchieveEvent()
	local tData = ctAchievementsConf
	self.m_tAchieveEvent = {}
	for nAchieveID,tAchieveData in pairs(tData) do
		local sEvent = tAchieveData["sDesc"]
		if not self.m_tAchieveEvent[sEvent] then
			self.m_tAchieveEvent[sEvent] = {}
		end
		table.insert(self.m_tAchieveEvent[sEvent],nAchieveID)
		local nType = tAchieveData["nType"]
		if not self.m_tTypeAchieve[nType] then
			self.m_tTypeAchieve[nType] = {}
		end
		table.insert(self.m_tTypeAchieve[nType],nAchieveID)
	end
	for nType,tAchieveID in pairs(self.m_tTypeAchieve) do
		table.sort(tAchieveID)
	end
end


--单事件推送
function CAchieve:PushAchieve(sKey,tData)
	if not self:CheckSysOpen() then
		return
	end

    if not self.m_tAchieveEvent[sKey] then
        return
    end
    tData = tData or {}
    self.m_tSendTypeAchieve = {}
    local nValue = tData["nValue"] or 1
    local tAchieveID = self.m_tAchieveEvent[sKey] or {}
    local nType
    local nDegreeType
    for _,nAchieveID in ipairs(tAchieveID) do
    	if self:ValidDoDegree(nAchieveID) then
    		nType = self:GetAchiveType(nAchieveID)
	    	nDegreeType = self:GetAchieveDegreeType(nAchieveID)
	    	if nDegreeType == 1 then
		    	self:AddDegree(sKey,nAchieveID,nValue)
		    elseif nDegreeType == 2 then
		    	self:SetDegree(sKey,nAchieveID,nValue)
		    end
		end
    end
    if nType then
    	if nDegreeType == 1 then
	    	self:AddTypeAchieveAmount(nType,nValue)
	    elseif nDegreeType == 2 then
	    	self:SetTypeAchieveAmount(nType,nValue)
	    end
    end
    if #self.m_tSendTypeAchieve > 0 then
    	self:SendTypeAchieve(self.m_tSendTypeAchieve)
    	self.m_tSendTypeAchieve = nil
    end
end

--多事件推送
function CAchieve:MultiPushAchieve(tKey,tData)
	if not self:CheckSysOpen() then
		return
	end

	tData = tData or {}
	local tValue = tData["tValue"] or {}
	self.m_tSendTypeAchieve = {}
	for nNo,sKey in ipairs(tKey) do
		if self.m_tAchieveEvent[sKey] then
			local nAdd = tValue[nNo] or 1
			local tAchieveID = self.m_tAchieveEvent[sKey] or {}
			local nType
			for _,nAchieveID in ipairs(tAchieveID) do
				if self:ValidDoDegree(nAchieveID) then
					nType = self:GetAchiveType(nAchieveID)
					local nDegreeType = self:GetAchieveDegreeType(nAchieveID)
					if nDegreeType == 1 then
						self:AddDegree(sKey,nAchieveID,nAdd)
					elseif nDegreeType == 2 then
						self:SetDegree(sKey,nAchieveID,nAdd)
					end
				end
			end
			if nType then
				self:AddTypeAchieveAmount(nType,nAdd)
			end
		end
	end
	if #self.m_tSendTypeAchieve > 0 then
		self:SendTypeAchieve(self.m_tSendTypeAchieve)
    	self.m_tSendTypeAchieve = nil
	end
end

function CAchieve:GetAchieveData(nAchieveID)
	local tData = ctAchievementsConf[nAchieveID]
	return tData
end

function CAchieve:HasAchieve(nAchieveID)
    local tData = self:GetAchieveData(nAchieveID)
    if tData then
    	return true
    end
    return false
end

function CAchieve:GetAchiveType(nAchieveID)
	local tData = ctAchievementsConf[nAchieveID]
	return tData["nType"]
end

--成就叠加类型
function CAchieve:GetAchieveDegreeType(nAchieveID)
	local tData = self:GetAchieveData(nAchieveID)
	return tData["nDegreeType"]
end

function CAchieve:AddTypeAchieveAmount(nType,nAdd)
	if not self.m_tAchieveDegree[nType] then
		self.m_tAchieveDegree[nType] = 0
	end
	self:MarkDirty(true)
	self.m_tAchieveDegree[nType] = self.m_tAchieveDegree[nType] + nAdd
end

function CAchieve:SetTypeAchieveAmount(nType,nAmount)
	if not self.m_tAchieveDegree[nType] then
		self.m_tAchieveDegree[nType] = 0
	end
	self:MarkDirty(true)
	self.m_tAchieveDegree[nType] = nAmount
end

function CAchieve:AddAchieve(nAchieveID)
    self:MarkDirty(true)
    self.m_oAchieve[nAchieveID] = self:CreateAchieve(nAchieveID)
    return self.m_oAchieve[nAchieveID]
end

function CAchieve:ValidDoDegree(nAchieveID)
	if not self:HasAchieve(nAchieveID) then
		return false
	end
	local oAchieve = self:GetAchieve(nAchieveID)
	if oAchieve and oAchieve:IsDone() then
		return false
	end
	return true
end

function CAchieve:AddDegree(sKey,nAchieveID,nAdd)
    if not self:HasAchieve(nAchieveID) then
        return
    end
    local oAchieve = self:GetAchieve(nAchieveID)
    if not oAchieve then
    	oAchieve = self:AddAchieve(nAchieveID)
    end
    if oAchieve and oAchieve:IsDone() then
    	return
    end
    self:MarkDirty(true)
    oAchieve:AddDegree(nAdd)
    local nAchieveType = self:GetAchiveType(nAchieveID)
    if oAchieve:IsDone(nAchieveID) then
    	self.m_tSendTypeAchieve = self.m_tSendTypeAchieve or {}
    	if not self:IsInTableList(self.m_tSendTypeAchieve,nAchieveType) then
			table.insert(self.m_tSendTypeAchieve,nAchieveType)
		end
    end
end

function CAchieve:SetDegree(sKey,nAchieveID,nAmount)
	if not self:HasAchieve(nAchieveID) then
        return
    end
    local oAchieve = self:GetAchieve(nAchieveID)
    if not oAchieve then
    	oAchieve = self:AddAchieve(nAchieveID)
    end
    if oAchieve and oAchieve:IsDone() then
    	return
    end
    self:MarkDirty(true)
    local nTargetDegree = oAchieve:ReachDegreeTarget()
    nAmount = math.min(nTargetDegree,nAmount)
    oAchieve:SetDegree(nAmount)
    local nAchieveType = self:GetAchiveType(nAchieveID)
    if oAchieve:IsDone(nAchieveID) then
    	self.m_tSendTypeAchieve = self.m_tSendTypeAchieve or {}
		if not self:IsInTableList(self.m_tSendTypeAchieve,nAchieveType) then
			table.insert(self.m_tSendTypeAchieve,nAchieveType)
		end
    end
end

function CAchieve:IsInTableList(t,nNum)
	for _,nValue in pairs(t) do
		if nValue==nNum then
			return true
		end
	end
	return false
end

function CAchieve:GetAchieveRewardReq(nAchieveID)
	if not self:CheckSysOpen(true) then
		return
	end

	local nType = self:GetAchiveType(nAchieveID)
	local oAchieve = self:GetAchieve(nAchieveID)
	if not oAchieve then
		return
	end
	if not oAchieve:IsDone() then
		self.m_oRole:Tips("成就未完成")
		return
	end
	if oAchieve:IsReward() then
		self.m_oRole:Tips("已领取成就奖励")
		return
	end
	self:MarkDirty(true)
	oAchieve:GiveReward(self.m_oRole)
	local tMsg = {}
	tMsg.tAchieve = oAchieve:PackData()
	self.m_oRole:SendMsg("GetAchieveRewardRet",tMsg)
	local oRole = self.m_oRole
    goLogger:EventLog(gtEvent.eAchieveReward,oRole,nAchieveID)
end

function CAchieve:TypeAchieveData(nType)
	local tData = {}
	local tCanReweardAchieveID = {}
	local nRewardAchieveID = 0
	local tAchieveID = self.m_tTypeAchieve[nType] or {}
	for _,nAchieveID in ipairs(tAchieveID) do
		local oAchieve = self:GetAchieve(nAchieveID)
		if oAchieve and oAchieve:CanReward() then
			if nRewardAchieveID == 0 or nRewardAchieveID > nAchieveID then
				nRewardAchieveID = nAchieveID
			end
		end
	end
	local nDegree = self.m_tAchieveDegree[nType] or 0
	tData.nType = nType
	tData.nDegree = nDegree
	tData.nRewardAchieveID = nRewardAchieveID
	return tData
end

--该类型当前进行的成就
function CAchieve:CurrentAchieve(nType)
	local tAchieveID = self.m_tTypeAchieve[nType] or {}
	for _,nAchieveID in ipairs(tAchieveID) do
		local oAchieve = self:GetAchieve(nAchieveID)
		if oAchieve and not oAchieve:IsReward() then
			return oAchieve:PackData()
		end
		if not oAchieve then
			local tData = {
				nID = nAchieveID,
				nDegree = 0,
				nDone = 0,
			}
			return tData
		end
	end
	local nLen = table.Count(tAchieveID)
	if nLen <= 0 then
		return {}
	end
	local nMaxAchieveID = tAchieveID[nLen]
	local oMaxAchieve = self:GetAchieve(nMaxAchieveID)
	return oMaxAchieve:PackData()
end

--登录发送
function CAchieve:SyncAchieveList()
	local tMsg = {}
	local tAchieveData = {}
	for nType,tAchieveID in pairs(self.m_tTypeAchieve) do
		local tData = self:TypeAchieveData(nType)
		table.insert(tAchieveData,tData)
	end
	tMsg.tAchieve = tAchieveData
	self.m_oRole:SendMsg("AchieveListRet",tMsg)
end

function CAchieve:PackAchieveObjData(nAchieveID)
	local oAchieve = self:GetAchieve(nAchieveID)
	local tData = {}
	if oAchieve then
		tData = oAchieve:PackData()
	else
		tData = {nID = nAchieveID,nDegree = 0,nDone = 0}
	end
	return tData
end

function CAchieve:OpenTypeAchieveReq(nType)
	if not self:CheckSysOpen(true) then
		return
	end

	local tAchieveID = self.m_tTypeAchieve[nType] or {}
	local tMsg = {}
	local tAchieveData = {}
	for _,nAchieveID in pairs(tAchieveID) do
		local tData = self:PackAchieveObjData(nAchieveID)
		table.insert(tAchieveData,tData)
	end
	tMsg.tAchieve = tAchieveData
	self.m_oRole:SendMsg("OpenTypeAchieveRet",tMsg)
end

--发送类型成就信息
function CAchieve:SendTypeAchieve(tTypeAchieve)
	local tMsg = {}
	local tAchieveData = {}
	for _,nAchieveType in pairs(tTypeAchieve) do
		local tData = self:TypeAchieveData(nAchieveType)
		table.insert(tAchieveData,tData)
	end
	tMsg.tAchieve = tAchieveData
	self.m_oRole:SendMsg("SendTypeAchieveRet",tMsg)
end

function CAchieve:DoLoginAchieve()
	if os.IsSameDay(self.m_nLoginTime,os.time(),0) then
		return
	end
	self:MarkDirty(true)
	self.m_nLoginTime = os.time()
	self:PushAchieve("累计登录天数",{nValue=1})
end

function CAchieve:OnLevelChange(nLevel)
	self:PushAchieve("角色等级",{nValue=nLevel})
end

function CAchieve:OnPowerChange(nPower)
	nPower = math.ceil(nPower)
	self:PushAchieve("人物战力",{nValue=nPower})
end