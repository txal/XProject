--全局模块基类
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CGModuleBase:Ctor(tModuleType)
	assert(tModuleType, "模块类型参数不能为空")
	self.m_tModuleType = tModuleType
end

function CGModuleBase:Init()
end

function CGModuleBase:LoadData()
end

function CGModuleBase:OnLoaded()
end

function CGModuleBase:Release()
end

--模块ID
function CGModuleBase:GetID()
	return self.m_tModuleType.nID
end

--模块类型
function CGModuleBase:GetType()
	return self.m_tModuleType
end

--模块名字
function CGModuleBase:GetName()
	return self.m_tModuleType.sName
end

function CGModuleBase:SaveData()
end

function CGModuleBase:MarkDirty()
	assert(false, "派生类未实现MarkDirty")
end

function CGModuleMgr:OnHourTimer()
end

function CGModuleBase:OnMinTimer()
end
