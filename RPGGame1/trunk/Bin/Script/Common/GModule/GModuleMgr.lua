--全局模块管理器
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CGModuleMgr:Ctor()
	self.m_tModuleMap = {}

	self.m_nMinTimer = nil
	self.m_nHourTimer = nil
	self.m_nSaveTimer = nil
end

--公用模块创建
function CGModuleMgr:_CommonModule()
	local oDBMgr = CDBMgr:new()
	local oLogger = CLogger:new()
	local oTimerMgr = CTimerMgr:new()
	local oServerMgr = CServerMgr:new()

	self:RegModule(oDBMgr)
	self:RegModule(oLogger)
	self:RegModule(oTimerMgr)
	self:RegModule(oServerMgr)
end

--初始化
function CGModuleMgr:Init(tModuleList)
	--注册公用模块
	self:_CommonModule()
	--注册自定义模块
	for _, oModule in ipairs(tModuleList) do
		self:RegModule(oModule)
	end
	--初始化
	self:_InitModule()
	--加载数据
	self:_LoadModuleData()
	--加载完成
	self:_OnModuleLoaded()
end

--释放
function CGModuleMgr:Release()
	local oTimerMgr = self:GetModule("TimerMgr")
	oTimerMgr:Clear(self.m_nMinTimer)
	oTimerMgr:Clear(self.m_nHourTimer)
	oTimerMgr:Clear(self.m_nSaveTimer)
	self:SaveData()
	
	for sName, oModule in pairs(self.m_tModuleMap) do
		oModule:Release()
	end
end

--初始化
function CGModuleMgr:_InitModule()
	for sName, oModule in pairs(self.m_tModuleMap) do
		oModule:Init()
	end
end

--加载数据
function CGModuleMgr:_LoadModuleData()
	for sName, oModule in pairs(self.m_tModuleMap) do
		oModule:LoadData()
	end
end

--加载数据完毕
function CGModuleMgr:_OnModuleLoaded()
	local oTimerMgr = self:GetModule("TimerMgr")
	self.m_nMinTimer = oTimerMgr:Interval(os.NextMinTime(os.time()), function() self:OnMinTimer() end)
	self.m_nHourTimer = oTimerMgr:Interval(os.NextHourTime(os.time()), function() self:OnHourTimer() end)
	self.m_nSaveTimer = oTimerMgr:Interval(gtGDef.tConst.nAutoSaveTime, function() self:SaveData() end)
	
	for nID, oModule in pairs(self.m_tModuleMap) do
		oModule:OnLoaded()
	end
end

--注册模块
function CGModuleMgr:RegModule(oModule)
	local tModule = oModule:GetType()
	assert(tModule, "模块未构造:"..tostring(oModule))
	assert(not self.m_tModuleMap[tModule.nID], "模块重复注册: "..tModule.nID)
	assert(not self.m_tModuleMap[tModule.sName], "模块名冲突: "..tModule.sName)
	self.m_tModuleMap[tModule.nID] = oModule
	self.m_tModuleMap[tModule.sName] = oModule
end

--通过模块名字取模块
function CGModuleMgr:GetModule(sName)
	return assert(self.m_tModuleMap[sName], "模块不存在:"..sName)
end

--保存数据
function CGModuleMgr:SaveData()
	for sName, oModule in pairs(self.m_tModuleMap) do
		oModule:SaveData()
	end
end

--整分钟定时器
function CGModuleMgr:OnMinTimer()
	for sName, oModule in pairs(self.m_tModuleMap) do
		oModule:OnMinTimer()
	end
end

--整点定时器
function CGModuleMgr:OnHourTimer()
	for sName, oModule in pairs(self.m_tModuleMap) do
		oModule:OnHourTimer()
	end
end

--角色上线
function CGModuleMgr:OnRoleOnline(oRole)
	for sName, oModule in pairs(self.m_tModuleMap) do
		oModule:OnRoleOnline(oRole)
	end
end

--角色断线
function CGModuleMgr:OnRoleDisconnect(oRole)
	for sName, oModule in pairs(self.m_tModuleMap) do
		oModule:OnRoleDisconnect(oRole)
	end
end

--角色释放
function CGModuleMgr:OnRoleReleased(oRole)
	for sName, oModule in pairs(self.m_tModuleMap) do
		oModule:OnRoleReleased(oRole)
	end
end

--角色进入场景
function CGModuleMgr:OnRoleEnterScene(oRole)
	for sName, oModule in pairs(self.m_tModuleMap) do
		oModule:OnRoleEnterScene(oRole)
	end
end

--角色离开场景
function CGModuleMgr:OnRoleLeaveScene(oRole, nDupID, nSceneID)
	for sName, oModule in pairs(self.m_tModuleMap) do
		oModule:OnRoleLeaveScene(oRole, nDupID, nSceneID)
	end
end

--角色离开副本
function CGModuleMgr:OnRoleLeaveDup(oRole, nDupID)
	for sName, oModule in pairs(self.m_tModuleMap) do
		oModule:OnRoleLeaveDup(oRole, nDupID)
	end
end

--角色等级变化
function CGModuleMgr:OnRoleLevelChange(oRole)
	for sName, oModule in pairs(self.m_tModuleMap) do
		oModule:OnRoleLeaveChange(oRole)
	end
end

--服务器关闭
function CGModuleMgr:OnServerClose(nServerID)
	for sName, oModule in pairs(self.m_tModuleMap) do
		oModule:OnServerClose(nServerID)
	end
end

--有服务关闭
function CGModuleMgr:OnServiceClose(nServerID, nServiceID)
	for sName, oModule in pairs(self.m_tModuleMap) do
		oModule:OnServiceClose(nServerID, nServiceID)
	end
end


goGModuleMgr = goGModuleMgr or CGModuleMgr:new()
--取全局模块接口
function GetGModule(sModuleName)
	return goGModuleMgr:GetModule(sModuleName)
end