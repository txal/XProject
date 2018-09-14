function CBuff:Ctor(oOwner, nBuffID)
	self.m_oOwner = oOwner
	self.m_nBuffID = nBuffID
	self.m_tConf = assert(ctBuffConf[nBuffID])
	self.m_tAddValue = {}
	self:Exec()
end

--执行BUFF
function CBuff:Exec()
	print("CBuff:Exec***", self.m_oOwner:GetName(), self.m_nBuffID)
    local nAOIID = self.m_oOwner:GetAOIID()
    local oScene = self.m_oOwner:GetScene()
	local tSessionList = oScene:GetSessionList(nAOIID, true)
	if self.m_tConf.nType == gtBuffType.eAttr then
		local nAttrID = self.m_tConf.nVal1
		local nAttrAdd = self.m_tConf.nVal2
		self.m_tAddValue[nAttrID] = nAttrAdd

		local oCppObj = self.m_oOwner:GetCppObj()
		local nCurrVal = oCppObj:GetFightParam(nAttrID) 
		local nNewVal = math.floor(nCurrVal * (1 + nAttrAdd * 0.0001))
		oCppObj:UpdateFightParam(nAttrID, nNewVal)

		local tAttrList = {{nID=nAttrID, nVal=nNewVal}}
		CmdNet.PBBroadcastExter(tSessionList, "ActorBattleAttrSync", {nAOIID=nAOIID, tAttr=tAttrList})

	elseif self.m_tConf.nType == gtBuffType.eMoveSpeed then
		local nSpeedAdd = self.m_tConf.nVal1
		self.m_tAddValue[1] = nSpeedAdd

		local oCppObj = self.m_oOwner:GetCppObj()
		local nCurrSpeed = oCppObj:GetFightParam(gtAttrDef.eSpeed)
		local nNewSpeed = nCurrSpeed + nSpeedAdd
		oCppObj:UpdateFightParam(gtAttrDef.eSpeed, nNewSpeed)

		if self.m_oOwner:GetObjType() == gtObjType.ePlayer then
			local tAttrList = {{nID=gtAttrDef.eSpeed, nVal=nNewSpeed}}
			CmdNet.PBSrv2Clt(self.m_oOwner:GetSession(), "ActorBattleAttrSync", {nAOIID=nAOIID, tAttr=tAttrList})
		end
		
	elseif self.m_tConf.nType == gtBuffType.eShotSpeed then
		--玩家客户端处理, 机器人不处理

	elseif self.m_tConf.nType == gtBuffType.eState then
		--暂略

	end
end

--广播中BUFF给场景内玩家
function CBuff:BroadcastAddBuff()
    local nAOIID = self.m_oOwner:GetAOIID()
    local oScene = self.m_oOwner:GetScene()
	local tSessionList = oScene:GetSessionList(nAOIID, true)
	local nBuffTime = self.m_tConf.nTime --因为是覆盖,所以时间不变
	CmdNet.PBBroadcastExter(tSessionList, "ActorAddBuffSync", {nAOIID=nAOIID, nBuffID=self.m_nBuffID, nBuffTime=nBuffTime})
end

--BUFF过期
function CBuff:Expire()
	print("CBuff:Expire***", self.m_oOwner:GetName(), self.m_nBuffID)
    local nAOIID = self.m_oOwner:GetAOIID()
    local oScene = self.m_oOwner:GetScene()
	local tSessionList = oScene:GetSessionList(nAOIID, true)
	if self.m_tConf.nType == gtBuffType.eAttr then
		local tAttrList = {}
		local oCppObj = self.m_oOwner:GetCppObj()
		for nAttrID, nAddVal in pairs(self.m_tAddValue) do
			local nCurrVal = oCppObj:GetFightParam(nAttrID)
			local nNewVal = math.floor(nCurrVal * (1 - nAddVal * 0.0001))
			oCppObj:UpdateFightParam(nAttrID, nNewVal)
			table.insert(tAttrList, {nID=nAttrID, nVal=nNewVal})
		end
		CmdNet.PBBroadcastExter(tSessionList, "ActorBattleAttrSync", {nAOIID=nAOIID, tAttr=tAttrList})

	elseif self.m_tConf.nType == gtBuffType.eMoveSpeed then
		local oCppObj = self.m_oOwner:GetCppObj()
		local nCurrSpeed = oCppObj:GetFightParam(gtAttrDef.eSpeed)
		local nNewSpeed = nCurrSpeed - self.m_tAddValue[1]
		oCppObj:UpdateFightParam(gtAttrDef.eSpeed, nNewSpeed)

		if self.m_oOwner:GetObjType() == gtObjType.ePlayer then
			tAttrList = {{nID=gtAttrDef.eSpeed, nVal=nNewSpeed}}
		    CmdNet.PBSrv2Clt(self.m_oOwner:GetSession(), "ActorBattleAttrSync", {nAOIID=nAOIID, tAttr=tAttrList})
		end

	end
	
    CmdNet.PBBroadcastExter(tSessionList, "ActorRemoveBuffSync", {nAOIID=nAOIID, nBuffID=self.m_nBuffID})
end
