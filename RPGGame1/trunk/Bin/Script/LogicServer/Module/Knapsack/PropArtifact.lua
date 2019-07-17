--神器使用
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CPropArtifact:Ctor(oModule, nID, nGrid, bBind, tPropExt)
	CPropBase.Ctor(self, oModule, nID, nGrid, bBind, tPropExt) --调用基类构造函数

	self.m_tBaseProperty = self:GetBaseProperty() 	--基础属性
end

function CPropArtifact:LoadData(tData)
	CPropBase.LoadData(self, tData) --基类数据

	self.m_tBaseProperty = tData.m_tBaseProperty
end

function CPropArtifact:GetBaseProperty()
	local tBaseProperty = {}
	return tBaseProperty
end

function CPropArtifact:SaveData()
	local tData = CPropBase.SaveData(self) --基类数据
	--自己数据

	tData.m_tBaseProperty = self.m_tBaseProperty
	return tData
end

--使用道具
function CPropArtifact:Use()
	local oRole = self.m_oModule.m_oRole
	if not oRole.m_oArtifact:IsSysOpen(true) then
		-- return oRole:Tips("神器系统尚未开启")
		return
	end
	local oArtifact = oRole.m_oArtifact:GetArtifact(self:GetID())
	if oArtifact then 
		return oRole:Tips("该神器已经激活")
	end
	--调用神器模块处理激活后的逻辑
	oRole.m_oArtifact:Activation(self:GetID())
	oRole.m_oKnapsack:SubGridItem(self:GetGrid(), self:GetID(), 1, "神器使用")
end
	