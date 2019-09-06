--全局模块基类
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CGModuleBase:Ctor(tModuleDef)
	assert(tModuleDef, "模块类型参数不能为空")
	self.m_tModuleDef = tModuleDef
end

function CGModuleBase:Init()
end

function CGModuleBase:LoadData()
end

function CGModuleBase:OnLoaded()
end

function CGModuleBase:SaveData()
end

function CGModuleBase:Release()
end

--模块定义
function CGModuleBase:GetModuleDef()
    return self.m_tModuleDef
end

function CGModuleBase:MarkDirty()
	assert(false, "派生类未实现MarkDirty")
end

function CGModuleMgr:OnHourTimer()
end

function CGModuleBase:OnMinTimer()
end

function CGModuleBase:OnRoleOnline(oRole)
end

function CGModuleBase:OnRoleDisconnect(oRole)
end

function CGModuleBase:OnRoleReleased(oRole)
end

function CGModuleBase:OnRoleEnterScene(oRole)
end

function CGModuleBase:OnRoleLeaveScene(oRole, nDupID, nSceneID)
end

function CGModuleBase:OnRoleLeaveDup(oRole, nDupID)
end

function CGModuleBase:OnRoleLevelChange(oRole)
end

--服务器关闭
function CGModuleBase:OnServerClose(nServerID)
end

--有服务关闭
function CGModuleBase:OnServiceClose(nServerID, nServiceID)
end
