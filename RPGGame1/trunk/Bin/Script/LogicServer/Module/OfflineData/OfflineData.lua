--离线数据管理，比如离线给玩家加物品等等，玩家上线的时候处理
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--离线数据键名
gtOffKeyType = 
{
	eAward = "award", 	--离线奖励
	eRoleUpdate = "roleupdate", --角色数据更新
	eAppellation = "appellation"  --称谓数据操作
}


function COfflineData:Ctor(oRole)
	self.m_oRole = oRole --玩家在线才有这个
end

--不需要加载和保存数据,直接操作数据库的
function COfflineData:LoadData()
end
function COfflineData:SaveData()
end

function COfflineData:GetType()
	return gtModuleDef.tOfflineData.nID, gtModuleDef.tOfflineData.sName
end

--加载旧数据
function COfflineData:LoadKeyData(nServerID, nRoleID, key)
	assert(nServerID and nRoleID and key, "参数错误")
	local oDB = goDBMgr:GetSSDB(nServerID, "user", nRoleID)
	local sData = oDB:HGet("offlinedata_"..nRoleID, key)
	local tData = sData == "" and {} or cjson.decode(sData)
	return tData
end

--保存新数据
function COfflineData:SaveKeyData(nServerID, nRoleID, key, data)
	assert(type(data) == "table", "数据类型错误")
	assert(nServerID and nRoleID and key and data, "参数错误")
	if CUtil:IsRobot(nRoleID) then 
		return 
	end
	local oDB = goDBMgr:GetSSDB(nServerID, "user", nRoleID)
	oDB:HSet("offlinedata_"..nRoleID, key, cjson.encode(data))
	print("保存离线数据:", nServerID, nRoleID, key, data)
end

--删除数据
function COfflineData:DelKeyData(nServerID, nRoleID, key)
	assert(nServerID and nRoleID and key, "参数错误")
	local oDB = goDBMgr:GetSSDB(nServerID, "user", nRoleID)
	oDB:HDel("offlinedata_"..nRoleID, key)
end

--角色上线事件,离线数据延迟到AfterEnterScene事件中处理
function COfflineData:Online()
end

--角色进入场景成功后事件,离线数据处理放这里
function COfflineData:AfterEnterScene()
	assert(self.m_oRole, "角色对象不存在")
	local nServerID = self.m_oRole:GetServer()
	local nRoleID = self.m_oRole:GetID()

	for _, sKey in pairs(gtOffKeyType) do
		local fnProcessFunc = COfflineData[sKey]
		if fnProcessFunc then
			local tData = self:LoadKeyData(nServerID, nRoleID, sKey)
			if next(tData) then
				--这里先删除数据,避免错误无法删除
				self:DelKeyData(nServerID, nRoleID, sKey)
				print("处理离线数据:", self.m_oRole:GetID(), self.m_oRole:GetName(), sKey, tData)
				fnProcessFunc(self, sKey, tData)
			end
		else
			LuaTrace("离线数据处理函数未实现", sKey)
		end
	end
end

--处理离线奖励
COfflineData[gtOffKeyType.eAward] = function(self, sKey, tData)
	for _, tAward in ipairs(tData) do
		for _, tItem in ipairs(tAward.tItemList) do
	        self.m_oRole:AddItem(tItem.nType, tItem.nID, tItem.nNum, tAward.sReason or "unknow", false, tItem.bBind, tItem.tPropExt)
		end
	end

end

--处理离线角色数据
COfflineData[gtOffKeyType.eRoleUpdate] = function(self, sKey, tData)
	self.m_oRole:DoRoleUpdate(tData)
end

COfflineData[gtOffKeyType.eAppellation] = function(self, sKey, tData)
	if not tData or not next(tData) then 
		return 
	end
	for k, v in ipairs(tData) do --必须使用ipairs有序处理
		print(string.format("开始更新玩家(%d)的称谓离线数据", self.m_oRole:GetID()))
		print(tData)
		--离线数据触发，不做佩戴称号提示
		if v.tExtData then 
			v.tExtData.bNotTips = true
		else
			local tExtData = {}
			tExtData.bNotTips = true
			v.tExtData = tExtData
		end
		self.m_oRole:AppellationUpdate(v)
	end
end



