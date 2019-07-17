--妖兽
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CPublicYaoShou:Ctor(nObjID, nConfID)
	self.m_bBattleStatus = false
	self.m_nObjID = nObjID
	--self.m_nPosID = nConfID 
end

function CPublicYaoShou:GetConf() return ctYaoShouTuXi[self:GetConfID()] end
function CPublicYaoShou:GetName() return self:GetConf().sName end
function CPublicYaoShou:GetLevel() return 0 end

-- function CPublicYaoShou:GetNativeObj() return self.m_oNativeObj end
-- function CPublicYaoShou:GetDupObj() return goDupMgr:GetDup(self:GetDupMixID()) end
-- function CPublicYaoShou:GetDupMixID() return self.m_oNativeObj:GetDupMixID() end
-- function CPublicYaoShou:GetAOIID() return self.m_oNativeObj:GetAOIID() end
--function CPublicYaoShou:GetFace() return self.m_oNativeObj:GetFace() end --当前面向
--function CPublicYaoShou:GetPos() return ctRandomPoint[self.m_nPosID].tPos end --当前X,Y坐标
--function CPublicYaoShou:SetPos(nPosX, nPosY) self.m_oNativeObj:SetPos(nPosX, nPosY) end --设置坐标
--function CPublicYaoShou:GetPosID() return self.m_nPosID end
--function CPublicYaoShou:SetPosID(nPosID) self.m_nPosID =  nPosID end
function CPublicYaoShou:GetDupID() return ctNpcConf[self.m_nObjID].nDupID end
function CPublicYaoShou:GetID() return self.m_nObjID end

--设置战斗状态
function CPublicYaoShou:SetBattleStatus(bValue)
	print("bValue------", bValue)
	self.m_bBattleStatus = bValue
	print("self.m_bBattleStatus---", self.m_bBattleStatus)
end

--获取战斗状态
function CPublicYaoShou:GetBattleStatus()
	return self.m_bBattleStatus
end

--视野数据
function CPublicYaoShou:GetViewData()
	local tInfo = {}
	tInfo.nDupID = self:GetDupID()
	tInfo.nYaoShouID = self.m_nObjID
	tInfo.nPosX = ctNpcConf[self.m_nObjID].tPos[1][1]
	tInfo.nPosY = ctNpcConf[self.m_nObjID].tPos[1][2]
	 print("CPublicYaoShou:GetViewData***", tInfo)
	 return tInfo
end