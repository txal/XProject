--微端下载奖励
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CWDDownload:Ctor(oRole)
	self.m_oRole = oRole
	self.m_nAwardState = 0 			--奖励状态(0.未下载 1.可领取 2.已领取)
	self.m_nResetTime = 0 			--重置时间
end 

function CWDDownload:LoadData(tData)
	if tData then 
		self.m_nAwardState = tData.m_nAwardState
		self.m_nResetTime = tData.m_nResetTime
	end
end

function CWDDownload:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)

	local tData = {}
	tData.m_nAwardState = self.m_nAwardState
	tData.m_nResetTime = self.m_nResetTime
	return tData
end

function CWDDownload:Online()
	self:WDDownloadInfoReq()
end

function CWDDownload:GetType()
	return gtModuleDef.tWDDownloadAward.nID, gtModuleDef.tWDDownloadAward.sName
end

--微端下载提示
function CWDDownload:OnWDDownloaded()
	if not self:CheckSysOpen(true) then
		return
	end

	if self.m_nAwardState > 0 then
		return
	end
	self.m_nAwardState = 1
	self:MarkDirty(true)
	self:WDDownloadInfoReq()
	goLogger:EventLog(gtEvent.eWDDownload, self.m_oRole)
end

--重置奖励状态
function CWDDownload:CheckReset()
	if not os.IsSameWeek(os.time(), self.m_nResetTime, 0) then 
		self.m_nResetTime = os.time()
		if self.m_nAwardState == 2 then
			self.m_nAwardState = 1
		end
		self:MarkDirty(true)
	end
end

--检测系统开放
function CWDDownload:CheckSysOpen(bTips)
	if not self.m_oRole.m_oSysOpen:IsSysOpen(77, bTips) then
		-- if bTips then
		-- 	self.m_oRole:Tips("微端系统未开启")
		-- end
		return
	end
	return true
end

--下载成功请求
function CWDDownload:WDDownloadedReq()
	self:OnWDDownloaded()
end

--微端下载界面请求
function CWDDownload:WDDownloadInfoReq()
	self:CheckReset()
	local tList = {}
	for _, tConf in ipairs(ctWDDownloadConf[1].tAward) do 
		table.insert(tList, {nItemID=tConf[1], nItemNum=tConf[2]})
	end
	local tMsg = {nState=self.m_nAwardState, tList=tList}
	self.m_oRole:SendMsg("WDDownloadInfoRet", tMsg)
	print("CWDDownload:WDDownloadInfoReq***", tMsg)
end

--领取微端下载奖励
function CWDDownload:GetWDDownloadAwardReq()
	if self.m_nAwardState == 0 then 
		return self.m_oRole:Tips("请先下载微端")
	end
	if self.m_nAwardState == 2 then 
		return self.m_oRole:Tips("已领取过奖励，请下周再来")
	end

	self.m_nAwardState = 2
	self:MarkDirty(true)

	local tAward = {}
	for _, tConf in ipairs(ctWDDownloadConf[1].tAward) do 
		table.insert(tAward, {nItemID=tConf[1], nItemNum=tConf[2]})
		self.m_oRole:AddItem(gtItemType.eProp, tConf[1], tConf[2], "下载微端奖励")
	end
	self.m_oRole:SendMsg("GetWDDownloadAwardRet", {tAward=tAward})
	self:WDDownloadInfoReq()
end

--GM重置
function CWDDownload:GMReset()
	self.m_nAwardState = 0
	self.m_nResetTime = os.time() 
	self:MarkDirty(true)
	self.m_oRole:Tips("重置微端信息成功")
end




