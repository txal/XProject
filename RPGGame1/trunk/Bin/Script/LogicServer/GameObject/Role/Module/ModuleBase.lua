function CModuleBase:Ctor()
	self.m_bDirty = false
end

function CModuleBase:LoadData(tData) end
function CModuleBase:SaveData() end
function CModuleBase:Release() end

function CModuleBase:IsDirty() return self.m_bDirty end
function CModuleBase:MarkDirty(bDirty) self.m_bDirty = bDirty end

function CModuleBase:GetType() assert(false) end
function CModuleBase:Online() end 		--上线
function CModuleBase:Disconnect() end 	--断线
function CModuleBase:Offline() end 		--下线(释放对象)

