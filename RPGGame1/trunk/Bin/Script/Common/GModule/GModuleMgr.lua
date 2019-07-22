--全局模块管理器
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CGModuleMgr:Ctor()
	self.m_tModuleIDMap = {}
	self.m_tModuleNameMap = {}

	self.m_nMinTimer = nil
	self.m_nHourTimer = nil
	self.m_nSaveTimer = nil
end

--公用模块创建
function CGModuleMgr:_CreateCommonModule()
	local oTimerMgr = CTimerMgr:new()
	local oServerMgr = CServerMgr:new()
	local oDBMgr = CDBMgr:new()
	local oLogger = CLogger:new()

	self:RegModule(oTimerMgr)
	self:RegModule(oServerMgr)
	self:RegModule(oDBMgr)
	self:RegModule(oLogger)
end

--初始化
function CGModuleMgr:Init()
	--创建公用模块
	self:_CreateCommonModule()
	--初始化
	self:_InitModule()
	--加载数据
	self:_LoadModuleData()
	--加载完成
	self:_OnModuleLoaded()
end

--释放
function CGModuleMgr:Release()
	local oTimerMgr = self:GetModuleByName("TimerMgr")
	oTimerMgr:Clear(self.m_nMinTimer)
	oTimerMgr:Clear(self.m_nHourTimer)
	oTimerMgr:Clear(self.m_nSaveTimer)
	self:SaveData()
	
	for nID, oModule in pairs(self.m_tModuleIDMap) do
		oModule:Release()
	end
end

--初始化
function CGModuleMgr:_InitModule()
	for nID, oModule in pairs(self.m_tModuleIDMap) do
		oModule:Init()
	end
end

--加载数据
function CGModuleMgr:_LoadModuleData()
	for nID, oModule in pairs(self.m_tModuleIDMap) do
		oModule:LoadData()
	end
end

--加载数据完毕
function CGModuleMgr:_OnModuleLoaded()
	local oTimerMgr = self:GetModuleByName("TimerMgr")
	self.m_nMinTimer = oTimerMgr:Interval(os.NextMinTime(os.time()), function() self:OnMinTimer() end)
	self.m_nHourTimer = oTimerMgr:Interval(os.NextHourTime(os.time()), function() self:OnHourTimer() end)
	self.m_nSaveTimer = oTimerMgr:Interval(gtGDef.tConst.nAutoSaveTime, function() self:SaveData() end)
	
	for nID, oModule in pairs(self.m_tModuleIDMap) do
		oModule:OnLoaded()
	end
end

--注册模块
function CGModuleMgr:RegModule(oModule)
	local tModule = oModule:GetType()
	assert(tModule, "模块未构造:"..tostring(oModule))
	assert(not self.m_tModuleIDMap[tModule.nID], "模块重复注册: "..tModule.nID)
	assert(not self.m_tModuleNameMap[tModule.sName], "模块名冲突: "..tModule.sName)
	self.m_tModuleIDMap[tModule.nID] = oModule
	self.m_tModuleNameMap[tModule.sName] = oModule
end

--通过模块ID取模块
function CGModuleMgr:GetModuleByID(nID)
	return assert(self.m_tModuleIDMap[nID], "模块不存在 ID:"..nID)
end

--通过模块名字取模块
function CGModuleMgr:GetModuleByName(sName)
	return self.m_tModuleNameMap[sName]
end

--保存数据
function CGModuleMgr:SaveData()
	for nID, oModule in pairs(self.m_tModuleIDMap) do
		oModule:SaveData()
	end
end

--整分钟定时器
function CGModuleMgr:OnMinTimer()
	for nID, oModule in pairs(self.m_tModuleIDMap) do
		oModule:OnMinTimer()
	end
end

--整点定时器
function CGModuleMgr:OnHourTimer()
	for nID, oModule in pairs(self.m_tModuleIDMap) do
		oModule:OnHourTimer()
	end
end


goGModuleMgr = goGModuleMgr or CGModuleMgr:new()
--取全局模块接口
function GetGModule(sModuleName)
	return goGModuleMgr:GetModuleByName(sModuleName)
end