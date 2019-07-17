--竞技场机器人(玩家镜像)
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert


function CArenaNpc:Ctor(nServerID, nRoleID)
	assert(nServerID > 0 and nRoleID >= 10000, "参数错误")
	self.m_nID = nRoleID
	--如果目标角色在线，则直接使用，否则从DB加载
	local oRole = goPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then
		oRole = CTempRole:new(nServerID, nRoleID)
		assert(oRole, "创建临时角色对象失败")
	end
	self.m_oRole = oRole
end

function CArenaNpc:GetBattleData()
	local tBattleData = self.m_oRole:MakeArenaNpcBattleData()
	return tBattleData
end

function CArenaNpc:Release()
	if self.m_oRole:IsTempRole() then 
		self.m_oRole:Release()
		self.m_oRole = nil
	end
end




