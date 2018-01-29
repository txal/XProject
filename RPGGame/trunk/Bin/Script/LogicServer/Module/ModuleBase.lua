function CModuleBase:Ctor()
	self.m_bDirty = false
end

function CModuleBase:OnRelease() end
function CModuleBase:LoadData(tData) end
function CModuleBase:SaveData() end
function CModuleBase:MarkDirty(bDirty) self.m_bDirty = bDirty end
function CModuleBase:IsDirty() return self.m_bDirty end
function CModuleBase:GetType() assert(false) end
function CModuleBase:Online() end
function CModuleBase:Offline() end
function CModuleBase:OnLevelChange(nOldLevel, nNewLevel) end