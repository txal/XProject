function CModuleBase:Ctor()
	self.m_bDirty = false
end

function CModuleBase:Release() end
function CModuleBase:LoadData(tData) end
function CModuleBase:SaveData() end
function CModuleBase:MarkDirty(bDirty) self.m_bDirty = bDirty end
function CModuleBase:GetType() assert(false) end
function CModuleBase:OnEnterLogic() end  --登录到逻辑服
function CModuleBase:Online() end --上线(这时候GlobalServer未上线)
function CModuleBase:AfterOnline() end --上线成功后
function CModuleBase:Offline() end --下线
function CModuleBase:OnLevelChange(nOldLevel, nNewLevel) end
function CModuleBase:IsDirty() return self.m_bDirty end

