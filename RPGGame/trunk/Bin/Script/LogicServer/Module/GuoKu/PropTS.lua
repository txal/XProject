--特殊类
function CPropTS:Ctor(oModule, nSysID, nGrid)
	CPropBase.Ctor(self, nSysID, nGrid)
	self.m_oModule = oModule
end

function CPropTS:LoadData(tData)
	CPropBase.LoadData(self, tData)
end

function CPropTS:SaveData()
	local tData = CPropBase.SaveData(self)
	return tData
end
