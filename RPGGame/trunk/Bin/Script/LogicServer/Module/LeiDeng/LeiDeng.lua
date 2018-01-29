--累登模块
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CLeiDeng:Ctor(oPlayer)
	self.m_oPlayer = oPlayer
	self.m_nRawLastLogin = 0 	--不受活动限制的上次登录时间
	self.m_nRawLoginCount = 0 	--不受活动限制的登录次数 
end

function CLeiDeng:LoadData(tData)
	if not tData then
		return
	end

	self.m_nRawLastLogin = tData.m_nRawLastLogin or 0
	self.m_nRawLoginCount = tData.m_nRawLoginCount or 0
end

function CLeiDeng:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)

	local tData = {}
	tData.m_nRawLastLogin = self.m_nRawLastLogin
	tData.m_nRawLoginCount = self.m_nRawLoginCount
	return tData
end

function CLeiDeng:GetType()
	return gtModuleDef.tLeiDeng.nID, gtModuleDef.tLeiDeng.sName
end

--上线
function CLeiDeng:Online()
	if not os.IsSameDay(os.time(), self.m_nRawLastLogin, 0) then
		self.m_nRawLoginCount = self.m_nRawLoginCount + 1
		self.m_nRawLastLogin = os.time()
		self:MarkDirty(true)

		self.m_oPlayer.m_oAchievements:SetAchievement(gtAchieDef.eCond1, 1)
	end

	if not self:IsOpen() then
		return
	end
	self:InfoReq()
end

--活动是否开启
function CLeiDeng:IsOpen()
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eLeiDeng)
	if oAct and oAct:IsOpen() then
		return true
	end
end

--取信息
function CLeiDeng:InfoReq()
	if not self:IsOpen() then
		return self.m_oPlayer:Tips("今天没有活动哦，请娘娘稍待几日")
	end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eLeiDeng)
	local nRounds = oAct:GetRounds()
	local nRemainDays = oAct:GetRemainDays()
	local nLoginCount = oAct:GetLoginCount(self.m_oPlayer)

	local tMsg = {nLoginCount=nLoginCount, nRemainDays=nRemainDays, tList={}}	
	for nID, tConf in ipairs(ctLeiDengConf) do
		if tConf.nRounds == nRounds then
			local nState = oAct:GetAwardState(self.m_oPlayer, nID)
			if nState == 0 then
				local nLoginCount = oAct:GetLoginCount(self.m_oPlayer)
				nState = nLoginCount >= tConf.nLoginCount and 1 or 0
			end
			local tInfo = {nID=nID, nState=nState}
			table.insert(tMsg.tList, tInfo)
		end
	end
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "LeiDengInfoRet", tMsg)
end

--领取奖励
function CLeiDeng:AwardReq(nID)
	if not self:IsOpen() then
		return self.m_oPlayer:Tips("今天没有活动哦，请娘娘稍待几日")
	end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eLeiDeng)
	local nState = oAct:GetAwardState(self.m_oPlayer, nID)
	if nState == 2 then
		return self.m_oPlayer:Tips("该奖励已经领取过了")
	end
	local tConf = ctLeiDengConf[nID]
	local nRounds = oAct:GetRounds()
	if tConf.nRounds ~= nRounds then
		return self.m_oPlayer("奖励轮次ID错误")
	end
	local nLoginCount = oAct:GetLoginCount(self.m_oPlayer)
	if nLoginCount < tConf.nLoginCount then
		return self.m_oPlayer:Tips("未达到领取条件")
	end
	for _, tAward in ipairs(tConf.tAward) do 
		self.m_oPlayer:AddItem(tAward[1], tAward[2], tAward[3], "累登奖励")
	end

	oAct:SetAwardState(self.m_oPlayer, nID, 2)
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "LeiDengAwardRet", {nID=nID})
	self:InfoReq()
end

--总登录天数
function CLeiDeng:GetLoginCount()
	return self.m_nRawLoginCount 
end