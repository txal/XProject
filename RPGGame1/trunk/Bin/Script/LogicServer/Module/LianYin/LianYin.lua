--萌宠联姻
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CLianYin:Ctor(oPlayer)
	self.m_oPlayer = oPlayer
	self.m_tLYRecvMap = {} --{[nID..nCharID]={nID=0,nGender=0,sName="",sIcon="",nJueWei=0,tAttr={},nTime=0,nLv=0,nTalentLv=0,nFZID=0,nCharID=0,sCharName="",bFullServer=false},...}
	self.m_tLYSendMap = {} --{[nID]={nID=0,nGender=0,sName="",sIcon="",nJueWei=0,tAttr={},nTime=0,nLv=0,nTalentLv=0,nFZID=0,nCharID=0,sCharName="",bReject=false,bFullServer=false},...}
	self.m_tLYAgreeMap = {} --{[nID]={nID=0,nGender=0,sName="",sIcon="",nJueWei=0,tAttr={},nTime=0,nLv=0,nTalentLv=0,nFZID=0,nCharID=0,sCharName="",bFullServer=false},...}
	self.m_bOpen = false
end

function CLianYin:LoadData(tData)
	if not tData then
		return
	end

	self.m_tLYRecvMap = tData.m_tLYRecvMap
	self.m_tLYSendMap = tData.m_tLYSendMap
	self.m_tLYAgreeMap = tData.m_tLYAgreeMap
	self.m_bOpen = tData.m_bOpen or false
end

function CLianYin:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false) 

	local tData = {}
	tData.m_tLYRecvMap = self.m_tLYRecvMap
	tData.m_tLYSendMap = self.m_tLYSendMap
	tData.m_tLYAgreeMap = self.m_tLYAgreeMap
	tData.m_bOpen = self.m_bOpen
	return tData
end

function CLianYin:GetType()
	return gtModuleDef.tLianYin.nID, gtModuleDef.tLianYin.sName
end

function CLianYin:SetOpen(bOpen)
	if self.m_bOpen ~= bOpen then
		self.m_bOpen = bOpen
		self:MarkDirty(true)
	end
end

function CLianYin:IsOpen()
	return self.m_bOpen
end

--收到联姻请求
function CLianYin:RecvLianYin(tHZData, nTarCharID, bServer)
	--角色不在线
	if nTarCharID then
		local tData = CLianYin:GetOfflineData(nTarCharID)
		tData.m_tLYRecvMap = tData.m_tLYRecvMap or {}
		local sKey = tHZData.nID..tHZData.nCharID
		if tData.m_tLYRecvMap[sKey] then --已有请求
			return
		end
		tData.m_tLYRecvMap[sKey] = tHZData
		CLianYin:SaveOfflineData(nTarCharID, tData)

		--小红点
		if not bServer then
			CRedPoint:MarkRedPointOffline(nTarCharID, gtRPDef.eLYReq, 1)
		end

	else
	--角色在线
		local sKey = tHZData.nID..tHZData.nCharID
		if self.m_tLYRecvMap[sKey] then --已有请求
			return 
		end
		self.m_tLYRecvMap[sKey] = tHZData
		self:MarkDirty(true)

		--小红点
		if not bServer then
			self.m_oPlayer.m_oRedPoint:MarkRedPoint(gtRPDef.eLYReq, 1)
		end
	end
end

--取离线数据
function CLianYin:GetOfflineData(nCharID)
	local _, sDBName = self:GetType()
	local sData = goDBMgr:GetSSDB("Player"):HGet(sDBName, nCharID)
	local tData = sData == "" and {} or cjson.decode(sData)
	tData.m_tLYSendMap = tData.m_tLYSendMap or {}
	tData.m_tLYAgreeMap = tData.m_tLYAgreeMap or {}
	return tData
end

--保存离线数据
function CLianYin:SaveOfflineData(nCharID, tData)
	local _, sDBName = self:GetType()
	goDBMgr:GetSSDB("Player"):HSet(sDBName, nCharID, cjson.encode(tData))
end

--生成萌宠数据
function CLianYin:GenHZData(oPlayer, oHZ, bYuanBao, bFullServer)
	local tHZData = {
		nID = oHZ.m_nID,
		nFZID = oHZ.m_nFZID,
		nCharID = oPlayer:GetCharID(),
		sCharName = oPlayer:GetName(),

		nLv = oHZ.m_nLv,
		sName = oHZ.m_sName,
		sIcon = oHZ.m_sIcon,
		tAttr = oHZ.m_tAttr,
		nGender = oHZ.m_nGender,
		nJueWei = oHZ.m_nJueWei,
		nTalentLv = oHZ.m_nTalentLv,

		bYuanBao = bYuanBao,
		bFullServer = bFullServer,
		nCaiLiID = oHZ:GetCaiLiID(),
		nTime = os.time(),
	}
	return tHZData
end

--检测和扣除和亲费用
function CLianYin:CheckCost(nCostType, nJueWei, bSub)
	--道具
	local tJWConf = ctHZTitleConf[nJueWei]
	if nCostType == 1 then
		local tProp = tJWConf.tProp[1]
		if tProp[1]	 > 0 then
			local nCurrNum = self.m_oPlayer:GetItemCount(tProp[1], tProp[2])
			if nCurrNum < tProp[3] then return
				self.m_oPlayer:Tips(string.format("%s不足", CGuoKu:PropName(tProp[2])))
			end
		end
		if bSub then
			self.m_oPlayer:SubItem(tProp[1], tProp[2], tProp[3], "萌宠联姻")
		end
		return true
	else
	--元宝
		if self.m_oPlayer:GetYuanBao() < tJWConf.nYuanBao then
			return self.m_oPlayer:YBDlg()
		end
		if bSub then
			self.m_oPlayer:SubItem(gtItemType.eCurr, gtCurrType.eYuanBao, tJWConf.nYuanBao, "萌宠联姻")
		end
		return true
	end
end

--记录联姻请求
function CLianYin:SendLianYin(oHZ, tHZData)
	local nCaiLiID = oHZ:GetCaiLiID()
	if nCaiLiID > 0 then
		self.m_oPlayer:AddItem(gtItemType.eProp, nCaiLiID, -1, "联姻扣除彩礼")
		oHZ:SetCaiLiID(0) --发出了联姻就清除彩礼
	end

	self.m_tLYSendMap[tHZData.nID] = tHZData
	self:MarkDirty(true)
end

--向指定玩家联姻
function CLianYin:PlayerLianYinReq(nHZID, nTarCharID, nCostType)
	assert(nCostType == 1 or nCostType == 2, "类型错误") --1道具; 2元宝
	local oHZ = assert(self.m_oPlayer.m_oZongRenFu:GetObj(nHZID), "萌宠不存在")
	if self.m_oPlayer:GetCharID() == nTarCharID then
		return self.m_oPlayer:Tips("不能和自己联姻")
	end
	if not goOfflineDataMgr:GetPlayer(nTarCharID) then
		return self.m_oPlayer:Tips("目标玩家不存在")
	end

	local oTarPlayer = goPlayerMgr:GetPlayerByCharID(nTarCharID)
	if oTarPlayer then
		if not oTarPlayer.m_oLianYin:IsOpen() then
			return self.m_oPlayer:Tips("对方暂无宠物")
		end
	else
		local tData = self:GetOfflineData(nTarCharID)
		if not tData.m_bOpen then
			return self.m_oPlayer:Tips("对方暂无宠物")
		end
	end

	if oHZ.m_nJueWei <= 0 then
		return self.m_oPlayer:Tips("没有品级不能联姻")
	end
	if self.m_tLYSendMap[nHZID] then
		return self.m_oPlayer:Tips("萌宠已经有联姻请求")
	end
	if self.m_tLYAgreeMap[nHZID] then
		return self.m_oPlayer:Tips("有玩家已同意该萌宠联姻请求")
	end
	--彩礼检测
	local nCaiLiID = oHZ:GetCaiLiID()
	if nCaiLiID > 0 then
		if self.m_oPlayer:GetItemCount(gtItemType.eProp, nCaiLiID) <= 0 then
			return self.m_oPlayer:Tips(string.format("%s不足", CGuoKu:PropName(nCaiLiID)))
		end
	end

	--检测消耗
	if not self:CheckCost(nCostType, oHZ:GetJueWei(), true) then
		return
	end

	--萌宠数据
	local tHZData = self:GenHZData(self.m_oPlayer, oHZ, nCostType==2)

	--玩家在线
	if oTarPlayer then
		oTarPlayer.m_oLianYin:RecvLianYin(tHZData)
	else
	--玩家不在线
		CLianYin:RecvLianYin(tHZData, nTarCharID)
	end
	self:SendLianYin(oHZ, tHZData)

	--日志
	goLogger:EventLog(gtEvent.eLianYinReq, self.m_oPlayer, "player", nHZID)
end

--全服玩家联姻
function CLianYin:ServerLianYinReq(nHZID, nCostType)
	assert(nCostType == 1 or nCostType == 2, "类型错误") --1道具; 2元宝
	local oHZ = assert(self.m_oPlayer.m_oZongRenFu:GetObj(nHZID), "萌宠不存在")

	if oHZ.m_nJueWei <= 0 then
		return self.m_oPlayer:Tips("没有品级不能联姻")
	end

	if self.m_tLYSendMap[nHZID] then
		return self.m_oPlayer:Tips("萌宠已经有联姻请求")
	end

	--检测彩礼
	local nCaiLiID = oHZ:GetCaiLiID()
	if nCaiLiID > 0 then
		if self.m_oPlayer:GetItemCount(gtItemType.eProp, nCaiLiID) <= 0 then
			return self.m_oPlayer:Tips(string.format("%s不足", CGuoKu:PropName(nCaiLiID)))
		end
	end

	--检测消耗
	if not self:CheckCost(nCostType, oHZ:GetJueWei(), true) then
		return
	end

	--萌宠数据
	local tHZData = self:GenHZData(self.m_oPlayer, oHZ, nCostType==2, true)
	goOfflineTask:AddLianYinTask(self.m_oPlayer, tHZData)
	self:SendLianYin(oHZ, tHZData)

	--在线的玩家通知一遍
	for nCharID, oPlayer in pairs(goPlayerMgr.m_tCharIDMap) do
		if nCharID ~= self.m_oPlayer:GetCharID() then
			oPlayer.m_oLianYin:PullLianYinTask()
		end
	end
	--日志
	goLogger:EventLog(gtEvent.eLianYinReq, self.m_oPlayer, "server", nHZID)
end

--检测联姻是否有效
function CLianYin:CheckValid()
	local nLYTime = ctHZEtcConf[1].nLYTime
	--发送的
	for nID, tHZData in pairs(self.m_tLYSendMap) do
		if tHZData.bReject and not tHZData.bFullServer then
			self:CancelLianYin(nID, 1) --被拒绝

		elseif tHZData.nTime + nLYTime <= os.time() then 
			self:CancelLianYin(nID, 2) --过期 

		end
	end

	--收到的
	local nCharID = self.m_oPlayer:GetCharID()
	for sKey, tHZData in pairs(self.m_tLYRecvMap) do
		assert(tHZData.nCharID ~= nCharID, "收到了自己联姻请求？")
		if tHZData.nTime + nLYTime <= os.time() then
			self.m_tLYRecvMap[sKey] = nil
			self:MarkDirty(true)
		else
			--清理不存在的联姻请求
			local oPlayer = goPlayerMgr:GetPlayerByCharID(tHZData.nCharID)
			if oPlayer then
				local tHZData = oPlayer.m_oLianYin.m_tLYSendMap[tHZData.nID]
				if not tHZData then
					self.m_tLYRecvMap[sKey] = nil
					self:MarkDirty(true)
					goOfflineTask:RemoveLianYin(sKey)
					LuaTrace(nCharID, "清理不存在的联姻请求:"..sKey)
				end
			else
				local tData = CLianYin:GetOfflineData(tHZData.nCharID)
				local nHZID = tHZData.nID
				if not tData.m_tLYSendMap[nHZID] then
					self.m_tLYRecvMap[sKey] = nil
					self:MarkDirty(true)
					goOfflineTask:RemoveLianYin(sKey)
					LuaTrace(nCharID, "清理不存在的联姻请求:"..sKey)
				end
			end
			--没有联姻请求了就清除小红点
			if not next(self.m_tLYRecvMap) then
				self.m_oPlayer.m_oRedPoint:MarkRedPoint(gtRPDef.eLYReq, 0)
			end
		end
	end
end

--取消联姻请求
function CLianYin:CancelLianYin(nHZID, nType)
	local tHZData = self.m_tLYSendMap[nHZID]
	if not tHZData then
		return
	end

	--清除全服联姻请求
	local sKey = tHZData.nID..tHZData.nCharID
	goOfflineTask:RemoveLianYin(sKey)
	self.m_tLYSendMap[nHZID] = nil
	self:MarkDirty(true)

	--返回资源
	local tJWConf = ctHZTitleConf[tHZData.nJueWei]
	if nType then --1被拒/2过期
		local sTips = ""
		if tHZData.bYuanBao then
			self.m_oPlayer:AddItem(gtItemType.eCurr, gtCurrType.eYuanBao, tJWConf.nYuanBao, "联姻过期")
			if nType == 1 then
				sTips = string.format("%s 拒绝联姻，返还 %d元宝", tHZData.sName, tJWConf.nYuanBao)
			else
				sTips = string.format("%s 联姻失败，返还 %d元宝", tHZData.sName, tJWConf.nYuanBao)
			end
		else
			local tProp = tJWConf.tProp[1]
			self.m_oPlayer:AddItem(tProp[1], tProp[2], tProp[3], "联姻过期")
			if nType == 1 then
				sTips = string.format("%s 拒绝联姻，返还 %s+1", tHZData.sName, CGuoKu:PropName(tProp[2]))
			else
				sTips = string.format("%s 联姻失败，返还 %s+1", tHZData.sName, CGuoKu:PropName(tProp[2]))
			end
		end
		self.m_oPlayer:Tips(sTips)

		--日志
		goLogger:EventLog(gtEvent.eCancelLianYin, self.m_oPlayer, nHZID, nType)

	else --主动结束
		local sTips = ""
		if tHZData.bYuanBao then
			local nYuanBao = math.floor(tJWConf.nYuanBao*0.8)
			self.m_oPlayer:AddItem(gtItemType.eCurr, gtCurrType.eYuanBao, nYuanBao, "取消联姻")
			sTips = string.format("成功终止联姻，返还 %d元宝",  nYuanBao)
		else
			local tProp = tJWConf.tProp[1]
			self.m_oPlayer:AddItem(tProp[1], tProp[2], tProp[3], "取消联姻")
			sTips = string.format("成功终止联姻，返还 %s+1",  CGuoKu:PropName(tProp[2]))
		end
		self.m_oPlayer:Tips(sTips)

		--日志
		goLogger:EventLog(gtEvent.eCancelLianYin, self.m_oPlayer, nHZID, 0)

	end
	--返回彩礼
	if (tHZData.nCaiLiID or 0) > 0 then
		self.m_oPlayer:AddItem(gtItemType.eProp, tHZData.nCaiLiID, 1, "终止联姻返回彩礼")
	end
	self:SyncLYList()
end

--标记拒绝联姻
function CLianYin:MarkReject(nHZID, nTarCharID)
	--角色不在线
	if nTarCharID then
		local tData = CLianYin:GetOfflineData(nTarCharID)
		if not tData.m_tLYSendMap[nHZID] then
			return
		end
		tData.m_tLYSendMap[nHZID].bReject = true
		CLianYin:SaveOfflineData(nTarCharID, tData)

	else
	--角色在线
		if not self.m_tLYSendMap[nHZID] then
			return
		end
		self.m_tLYSendMap[nHZID].bReject = true
		self:MarkDirty(true)
		self:CheckValid()

	end
end

--拒绝联姻
function CLianYin:RejectLianYin(nTarCharID, nTarHZID)
	self:CheckValid()

	if nTarCharID > 0 and nTarHZID > 0 then
	--拒绝指定玩家联姻
		local sKey = nTarHZID..nTarCharID
		if not self.m_tLYRecvMap[sKey] then
			return self.m_oPlayer:Tips("联姻请求不存在")
		end
		self.m_tLYRecvMap[sKey] = nil
		self:MarkDirty(true)

		local oPlayer = goPlayerMgr:GetPlayerByCharID(nTarCharID)
		if oPlayer then --在线
			oPlayer.m_oLianYin:MarkReject(nTarHZID)
		else --不在线
			CLianYin:MarkReject(nTarHZID, nTarCharID)
		end

		--日志
		goLogger:EventLog(gtEvent.eRejectLianYin, self.m_oPlayer, nTarCharID, nTarHZID)

	else
	--拒绝所有联姻
		for sKey, tHZData in pairs(self.m_tLYRecvMap) do
			local oPlayer = goPlayerMgr:GetPlayerByCharID(tHZData.nCharID)
			if oPlayer then --在线
				oPlayer.m_oLianYin:MarkReject(tHZData.nID)
			else --不在线
				CLianYin:MarkReject(tHZData.nID, tHZData.nCharID)
			end
		end
		self.m_tLYRecvMap = {}
		self:MarkDirty(true)

		--日志
		goLogger:EventLog(gtEvent.eRejectLianYin, self.m_oPlayer, "all")
	end
	self:SyncLYList()
end

--同意联姻
function CLianYin:AgreeLianYin(nSrcHZID, nTarCharID, nTarHZID, nCostType)
	self:CheckValid()
	local nCharID = self.m_oPlayer:GetCharID()
	if nCharID == nTarCharID then
		return self.m_oPlayer:Tips("不能自己跟自己结婚")
	end

	--如果有联姻请求不能联姻
	if self.m_tLYSendMap[nSrcHZID] then
		return self.m_oPlayer:Tips("请先终止已发出的联姻申请")
	end
	
	local sKey = nTarHZID..nTarCharID
	local tHZData = self.m_tLYRecvMap[sKey]
	if not tHZData then
		return self.m_oPlayer:Tips("联姻邀请不存在")
	end

	local oSrcHZ = self.m_oPlayer.m_oZongRenFu:GetObj(nSrcHZID)
	if oSrcHZ.m_nJueWei ~= tHZData.nJueWei then
		return self.m_oPlayer:Tips("不同品级萌宠不能联姻")
	end
	if oSrcHZ.m_nTalentLv ~= tHZData.nTalentLv then
		return self.m_oPlayer:Tips("不同萌宠类型不能联姻")
	end
	if oSrcHZ.m_nGender == tHZData.nGender then
		return self.m_oPlayer:Tips("同性萌宠不能联姻")
	end
	if oSrcHZ:IsMarried() then
		return self.m_oPlayer:Tips("您的萌宠已经结婚")
	end
	--彩礼检测	
	local nCaiLiID = oSrcHZ:GetCaiLiID()
	if nCaiLiID > 0 then
		if self.m_oPlayer:GetItemCount(gtItemType.eProp, nCaiLiID) <= 0 then
			return self.m_oPlayer:Tips(string.format("%s不足", CGuoKu:PropName(nCaiLiID)))
		end
	end
	--检测和亲费用不扣除
	if not self:CheckCost(nCostType, tHZData.nJueWei, false) then
		return
	end
	self.m_tLYRecvMap[sKey] = nil
	self:MarkDirty(true)

	local bRes = false
	local oTarPlayer = goPlayerMgr:GetPlayerByCharID(nTarCharID)
	if oTarPlayer then
	--在线
		bRes = oTarPlayer.m_oLianYin:DoMarry(self.m_oPlayer, oSrcHZ, nTarHZID)
	else
	--不在线
		bRes = CLianYin:DoMarry(self.m_oPlayer, oSrcHZ, nTarHZID, nTarCharID)
	end
	if bRes then
		--清除彩礼
		if nCaiLiID > 0 then
			self.m_oPlayer:AddItem(gtItemType.eProp, nCaiLiID, -1, "同意联姻扣除彩礼")
			oSrcHZ:SetCaiLiID(0)
		end
		--扣除和亲费用
		self:CheckCost(nCostType, tHZData.nJueWei, true)
	end
	self:SyncLYList()

	--日志
	goLogger:EventLog(gtEvent.eAgreeLianYin, self.m_oPlayer, nSrcHZID, nTarCharID, nTarHZID, nCostType, bRes)
end

--结婚
function CLianYin:DoMarry(oSrcPlayer, oSrcHZ, nTarHZID, nTarCharID)
	if (nTarCharID or 0) > 0 then --不在线
		local tData = CLianYin:GetOfflineData(nTarCharID)
		if not tData.m_tLYSendMap[nTarHZID] then
			return oSrcPlayer:Tips("联姻请求已过期或不存在")
		end
		local tTarHZData = tData.m_tLYSendMap[nTarHZID] 
		tData.m_tLYSendMap[nTarHZID] = nil
		tData.m_tLYAgreeMap[nTarHZID] = self:GenHZData(oSrcPlayer, oSrcHZ)
		CLianYin:SaveOfflineData(nTarCharID, tData)

		--清除全局的联姻申请
		local sKey = nTarHZID..nTarCharID
		goOfflineTask:RemoveLianYin(sKey)

		--同意方
		oSrcHZ:Married(tTarHZData)
		local tInfo = {
			sSrcName = oSrcHZ.m_sName, 
			sSrcIcon = oSrcHZ.m_sIcon, 
			sTarName = tTarHZData.sName,
			sTarIcon = tTarHZData.sIcon,
			tAttr = tTarHZData.tAttr,
		}
		Network.PBSrv2Clt(oSrcPlayer:GetSession(), "LYSuccessRet", {tList={tInfo}})
		--小红点
		CRedPoint:MarkRedPointOffline(nTarCharID, gtRPDef.eLYAgree, 1)

	else --在线
		if not self.m_tLYSendMap[nTarHZID] then
			return oSrcPlayer:Tips("联姻请求已过期或不存")
		end
		local oTarHZ = self.m_oPlayer.m_oZongRenFu:GetObj(nTarHZID)
		if oTarHZ:IsMarried() then
			return oSrcPlayer:Tips("对方萌宠已结婚")
		end
		--请求方
		local tSrcHZData = self:GenHZData(oSrcPlayer, oSrcHZ)
		oTarHZ:Married(tSrcHZData)

		--清除申请	
		local tTarHZData = self.m_tLYSendMap[nTarHZID]
		self.m_tLYSendMap[nTarHZID] = nil
		self:MarkDirty(true)

		--清除全局的联姻申请
		nTarCharID = self.m_oPlayer:GetCharID()
		local sKey = nTarHZID..nTarCharID
		goOfflineTask:RemoveLianYin(sKey)

		--同意方
		oSrcHZ:Married(tTarHZData)

		--请求方
		local tTarInfo = {
			sSrcName = tTarHZData.sName,
			sSrcIcon = tTarHZData.sIcon,
			sTarName = tSrcHZData.sName, 
			sTarIcon = tSrcHZData.sIcon,
			tAttr = tSrcHZData.tAttr,
		}
		Network.PBSrv2Clt(self.m_oPlayer:GetSession(), "LYSuccessRet", {tList={tTarInfo}})

		--同意方
		local tSrcInfo = {
			sSrcName = tSrcHZData.sName, 
			sSrcIcon = tSrcHZData.sIcon, 
			sTarName = tTarHZData.sName,
			sTarIcon = tTarHZData.sIcon,
			tAttr = tTarHZData.tAttr,
		}
		Network.PBSrv2Clt(oSrcPlayer:GetSession(), "LYSuccessRet", {tList={tSrcInfo}})

		--小红点
		self.m_oPlayer.m_oRedPoint:MarkRedPoint(gtRPDef.eLYAgree, 1)

	end
	return true
end

--检测离线联姻
function CLianYin:CheckOfflineMarry()
	local tList = {}
	for nID, tHZData in pairs(self.m_tLYAgreeMap) do
		local oHZ = self.m_oPlayer.m_oZongRenFu:GetObj(nID)
		if oHZ and not oHZ:IsMarried() then
			oHZ:Married(tHZData)

			local tInfo = {
				sSrcName = oHZ.m_sName, 
				sSrcIcon = oHZ.m_sIcon, 
				sTarName = tHZData.sName,
				sTarIcon = tHZData.sIcon,
				tAttr = tHZData.tAttr,
			}
			table.insert(tList, tInfo)
		end
	end
	self.m_tLYAgreeMap = {}
	self:MarkDirty(true)

	if #tList > 0 then
		Network.PBSrv2Clt(self.m_oPlayer:GetSession(), "LYSuccessRet", {tList=tList})
	end
end

--取已发送的联姻请求
function CLianYin:GetSendLY(nHZID)
	self:CheckValid()
	return self.m_tLYSendMap[nHZID]
end

--玩家上线日志
function CLianYin:Online()
	self:PullLianYinTask()
end

--拉取全服联姻请求
function CLianYin:PullLianYinTask()
	if not self.m_bOpen then
		return
	end

	local nCharID = self.m_oPlayer:GetCharID()
	local tLianYinMap = goOfflineTask:GetLianYinTask()
	for sKey, tHZData in pairs(tLianYinMap) do
		if tHZData.nCharID == nCharID or (tHZData.tPullMap and tHZData.tPullMap[nCharID]) then
		else
			goOfflineTask:MarkLianYin(sKey, nCharID)
			local tDataCopy = table.DeepCopy(tHZData)
			self:RecvLianYin(tDataCopy, nil, true)
		end
	end
end

--联姻列表同步
function CLianYin:SyncLYList()
	local tList = {}
	for sKey, tHZData in pairs(self.m_tLYRecvMap) do 
		local tInfo = {
			nID = tHZData.nID, 
			sName = tHZData.sName,
			sIcon = tHZData.sIcon,
			tAttr = tHZData.tAttr,
			nFZID = tHZData.nFZID,
			nGender = tHZData.nGender,
			nJueWei = tHZData.nJueWei,
			nCaiLiID = tHZData.nCaiLiID,

			nCharID = tHZData.nCharID,
			sCharName = tHZData.sCharName,
		}
		table.insert(tList, tInfo)
	end
	Network.PBSrv2Clt(self.m_oPlayer:GetSession(), "LYListRet", {tList=tList})
end

--联姻列表请求
function CLianYin:LYListReq()
	self:CheckValid()
	self:CheckOfflineMarry()
	
	self:SyncLYList()
	--小红点
	self.m_oPlayer.m_oRedPoint:MarkRedPoint(gtRPDef.eLYReq, 0)
	self.m_oPlayer.m_oRedPoint:MarkRedPoint(gtRPDef.eLYAgree, 0)
end

--符合条件萌宠列表
 function CLianYin:MatchHZReq(nTarCharID, nTarHZID)
	self:CheckValid()
	local sKey = nTarHZID..nTarCharID
	local tHZData = self.m_tLYRecvMap[sKey]
	if not tHZData then
		return self.m_oPlayer:Tips("联姻请求已过期或不存在")
	end

	local tList = {}
	for nHZID, oHZObj in pairs(self.m_oPlayer.m_oZongRenFu.m_tHZMap) do
		if oHZObj.m_nJueWei == tHZData.nJueWei
			and oHZObj.m_nGender ~= tHZData.nGender
			and oHZObj.m_nTalentLv == tHZData.nTalentLv
			and not oHZObj:IsMarried() then

			local tInfo = {
				nHZID = nHZID, 	
				nJueWei = oHZObj.m_nJueWei,
				sName = oHZObj.m_sName,
				sIcon = oHZObj.m_sIcon,
				nFZID = oHZObj.m_nFZID,
				tAttr = oHZObj.m_tAttr,
				nGender = oHZObj.m_nGender,
			}	
			table.insert(tList, tInfo)
		end
	end
	print("CLianYin:MatchHZReq***", tHZData.nGender, tList)
	Network.PBSrv2Clt(self.m_oPlayer:GetSession(), "LYHZMatchListRet", {tList=tList})
end
