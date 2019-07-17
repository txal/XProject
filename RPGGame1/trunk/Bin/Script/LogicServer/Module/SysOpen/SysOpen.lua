--系统开放控制模块
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--类型
gtSysOpenHandle = 
{
	[2] = function(oRole, nSysID) oRole.m_oShiMenTask:OnSysOpen(nSysID) end,
	[5] = function(oRole, nSysID) oRole.m_oTaskSystem:OnSysOpen(nSysID) end,
	[48] = function(oRole, nSysID) oRole.m_oShangJinTask:OnSysOpen(nSysID) end,
	[55] = function(oRole, nSysID)  oRole.m_oDrawSpirit:OnSysOpen() end,
	[21] = function(oRole, nSysID) oRole.m_oSkill:OnSysOpen() end,
}

--构造函数
function CSysOpen:Ctor(oRole)
	self.m_oRole = oRole
	self.m_tOpenSysMap = {} 	--已开放系统{[sysid]=flag,...}
end

function CSysOpen:LoadData(tData)
	if not tData then
		return
	end
	self.m_tOpenSysMap = tData.m_tOpenSysMap1 or {}
end

function CSysOpen:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)

	local tData = {}
	tData.m_tOpenSysMap1 = self.m_tOpenSysMap
	return tData
end

function CSysOpen:GetType()
	return gtModuleDef.tSysOpen.nID, gtModuleDef.tSysOpen.sName
end

function CSysOpen:Online()
    self:CheckSysOpen(true)
	self:SysOpenList()
end

--同步开发列表
function CSysOpen:SysOpenList()
	local tList = {}
	for nID, nFlag in pairs(self.m_tOpenSysMap) do
		if nFlag == gtSysOpenFlag.eOpen then
			table.insert(tList, nID)
		end
	end
	self.m_oRole:SendMsg("OpenSysListRet", {tList=tList})
	print("系统开放列表******", self.m_oRole:GetAccountName(), tList)
end

--检测系统开放
--@bOnline 是否玩家上线
function CSysOpen:CheckSysOpen(bOnline)
	local nLevel = self.m_oRole:GetLevel()

	local tNewOpen = {}
	local nServerLv = goServerMgr:GetServerLevel(self.m_oRole:GetServer())
	local nCompTarTaskID = self.m_oRole.m_oTargetTask:GetCompTaskID()
	for nID, tConf in pairs(ctSysOpenConf) do
		if tConf.bOpen then
			if (self.m_tOpenSysMap[nID] or 0) == 0 then
				local bOpen = true
				if tConf.nLevel > 0 then
					if nLevel < tConf.nLevel then
						bOpen = false
					end
				end
				if bOpen and tConf.nTask > 0 then
					if nCompTarTaskID < tConf.nTask then
						bOpen = false
					end
				end
				if bOpen and tConf.nServerLv > 0 then
					if nServerLv < tConf.nServerLv then
						bOpen = false
					end
				end
				if bOpen then
					self.m_tOpenSysMap[nID] = gtSysOpenFlag.eOpen
					table.insert(tNewOpen, nID)
				end
			end
		end
	end
	if #tNewOpen <= 0 then
		return
	end
	self:MarkDirty(true)
	for k, nSysID in ipairs(tNewOpen) do 
		self:OnSysOpen(nSysID)
	end
	if not bOnline then
		self:SyncSystemOpen(tNewOpen)
	end
end

--同步新系统开放
function CSysOpen:SyncSystemOpen(tOpenList)
	self.m_oRole:SendMsg("SysOpenRet", {tList=tOpenList})
	print("新系统开放******", self.m_oRole:GetAccountName(), tOpenList)
end

--角色等级变化
function CSysOpen:OnLevelChange(nLevel)
	self:CheckSysOpen()
end

--服务器等级变化
function CSysOpen:OnServerLvChange()
	self:CheckSysOpen()
end

--任务完成
function CSysOpen:OnTargetTaskCommit(nTaskID)
	self:CheckSysOpen()
end

function CSysOpen:OnSysOpen(nSysID, bNotSyncGlobal)
	local fnHandle = gtSysOpenHandle[nSysID]
	if fnHandle then 
		fnHandle(self.m_oRole, nSysID)
	end
	self.m_oRole.m_oDailyActivity:OnSysOpen()		--日程刷新参加按钮
	self.m_oRole.m_oWillOpen:OnSysOpen(nSysID)

	if not bNotSync then 
		local tSysData = self.m_tOpenSysMap[nSysID]
		local tGlobalServiceList = goServerMgr:GetGlobalServiceList()
		for _, tConf in pairs(tGlobalServiceList) do
			if tConf.nServer == self.m_oRole:GetServer() or tConf.nServer == gnWorldServerID then
				Network.oRemoteCall:Call("OnSysOpenReq", tConf.nServer, tConf.nID, self.m_oRole:GetSession(), 
					self.m_oRole:GetID(), nSysID, tSysData)
			end
		end
	end
end

function CSysOpen:OnSysClose(nSysID)
	local tSysData = self.m_tOpenSysMap[nSysID]
	local tGlobalServiceList = goServerMgr:GetGlobalServiceList()
    for _, tConf in pairs(tGlobalServiceList) do
        if tConf.nServer == self.m_oRole:GetServer() or tConf.nServer == gnWorldServerID then
			Network.oRemoteCall:Call("OnSysCloseReq", tConf.nServer, tConf.nID, self.m_oRole:GetSession(), 
				self.m_oRole:GetID(), nSysID, tSysData)
        end
    end
end

--系统是否开放
function CSysOpen:IsSysOpen(nSysID, bTips)
	local tConf = ctSysOpenConf[nSysID] 
	if not tConf then
		return
	end

	if self.m_tOpenSysMap[nSysID] == gtSysOpenFlag.eOpen then
		return true
	end

	if bTips and tConf.sTips ~= "0" then
		self.m_oRole:Tips(tConf.sTips)
	end
end

--取未开放提示
function CSysOpen:SysOpenTips(nSysID)
    local tConf = ctSysOpenConf[nSysID] 
    if tConf and tConf.sTips ~= "0" then
        return tConf.sTips
    end
    return "系统未开启"
end

--手动关闭系统
function CSysOpen:CloseSystem(nSysID)
	if not self.m_tOpenSysMap[nSysID] or self.m_tOpenSysMap[nSysID] ~= gtSysOpenFlag.eClose then 
		self.m_tOpenSysMap[nSysID] = gtSysOpenFlag.eClose
		self:MarkDirty(true)
		self:OnSysClose(nSysID)
		self:SysOpenList()
	end
end

--手动开启系统
function CSysOpen:OpenSystem(nSysID)
	if not self.m_tOpenSysMap[nSysID] or self.m_tOpenSysMap[nSysID] ~= gtSysOpenFlag.eOpen then 
		self.m_tOpenSysMap[nSysID] = gtSysOpenFlag.eOpen
		self:OnSysOpen(nSysID)
		self:MarkDirty(true)	
		self:SyncSystemOpen({nSysID})
	end
end

function CSysOpen:OpenAll()
	local tSysOpenList = {}
	for nID, tConf in pairs(ctSysOpenConf) do
		if not self.m_tOpenSysMap[nID] or self.m_tOpenSysMap[nID] ~= gtSysOpenFlag.eOpen then 
			self.m_tOpenSysMap[nID] = gtSysOpenFlag.eOpen
			self:OnSysOpen(nID, true)
			tSysOpenList[nID] = self.m_tOpenSysMap[nID]
		end
	end

	--批量通知
	local tSysData = self.m_tOpenSysMap[nSysID]
	local tGlobalServiceList = goServerMgr:GetGlobalServiceList()
	for _, tConf in pairs(tGlobalServiceList) do
		if tConf.nServer == self.m_oRole:GetServer() or tConf.nServer == gnWorldServerID then
			Network.oRemoteCall:Call("OnSysOpenListReq", tConf.nServer, tConf.nID, 
				self.m_oRole:GetSession(), self.m_oRole:GetID(), tSysOpenList)
		end
	end

	self:MarkDirty(true)
	self:SysOpenList()
end

--GM开启所有系统
function CSysOpen:GMOpenAll()
	do 
		return self.m_oRole:Tips("该指令已屏蔽,会引发问题")
	end
	self:OpenAll()
	self.m_oRole:Tips("开放所有系统成功,请重新登录")
end

