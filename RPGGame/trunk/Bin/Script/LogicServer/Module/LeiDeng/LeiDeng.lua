--累登模块
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CLeiDeng:Ctor(oRole)
	self.m_oRole = oRole
	self.m_nRawLastLogin = 0 	--上次登录时间
	self.m_nRawLoginCount = 0 	--登录次数
	self.m_tLDAwardState = {}  	--累登奖励状态
end

function CLeiDeng:LoadData(tData)
	if not tData then
		return
	end

	self.m_nRawLastLogin = tData.m_nRawLastLogin or 0
	self.m_nRawLoginCount = tData.m_nRawLoginCount or 0
	self.m_tLDAwardState = tData.m_tLDAwardState or {}
end

function CLeiDeng:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)

	local tData = {}
	tData.m_nRawLastLogin = self.m_nRawLastLogin
	tData.m_nRawLoginCount = self.m_nRawLoginCount
	tData.m_tLDAwardState = self.m_tLDAwardState
	return tData
end

function CLeiDeng:GetType()
	return gtModuleDef.tLeiDeng.nID, gtModuleDef.tLeiDeng.sName
end

--上线
function CLeiDeng:Online()
	self:InfoReq()
end

--检测累登状态
function CLeiDeng:CheckLeideng()
	local nTime = ctLeiDengEtcConf[1].nCountTime
	if not os.IsSameDay(os.time(), self.m_nRawLastLogin, nTime) then
		self.m_nRawLoginCount = self.m_nRawLoginCount + 1
		self.m_nRawLastLogin = os.time()
		self:MarkDirty(true)
	end
end

--累登界面
function CLeiDeng:InfoReq()
	self:CheckLeideng()
	local tMsg = {nLoginCount=self.m_nRawLoginCount, tList={}, bFinish=true}	
	for nID, tConf in pairs(ctLeiDengAwardConf) do
		local nState = self.m_tLDAwardState[nID] and 2 or 0
		if nState <= 0 then 	
			nState = self.m_nRawLoginCount >= tConf.nLoginDays and 1 or 0
		end
		if nState ~= 2 then 
			tMsg.bFinish = false
		end
		local nRemainDays = math.max(0, tConf.nLoginDays - self.m_nRawLoginCount)
		local tInfo = {nID=nID, nState=nState, nRemainDays=nRemainDays}
		table.insert(tMsg.tList, tInfo)
	end
	self.m_oRole:SendMsg("LDInfoRet", tMsg)
end

--领取奖励
function CLeiDeng:AwardReq(nID)
	if self.m_tLDAwardState[nID] then 
		return self.m_oRole:Tips("已领取")
	end 
	local tConf = assert(ctLeiDengAwardConf[nID], "该奖励不存在"..nID)
	if self.m_nRawLoginCount < tConf.nLoginDays then
		return self.m_oRole:Tips("未达到领取条件")
	end
	for _, tAward in ipairs(tConf.tAward) do 
		self.m_oRole:AddItem(tAward[1], tAward[2], tAward[3], "累登奖励")
	end

	self.m_tLDAwardState[nID] = 2
	self:MarkDirty(true)
	self.m_oRole:SendMsg("LDAwardRet", {nID=nID})
	self:InfoReq()
end

--总登录天数
function CLeiDeng:GetLoginCount()
	return self.m_nRawLoginCount 
end