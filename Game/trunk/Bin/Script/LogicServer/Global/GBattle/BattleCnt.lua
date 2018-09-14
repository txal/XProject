--所有全局战斗管理器的容器

function CBattleCnt:Ctor()
	self.m_nRoomInc = 0
	self.m_tBattleMgrMap = {}
end

function CBattleCnt:RegBattleMgr()
	self.m_tBattleMgrMap[gtBattleType.eBugStorm] = CBugStormMgr:new()
	self.m_tBattleMgrMap[gtBattleType.eBugHole] = CBugHoleMgr:new()
end

function CBattleCnt:GetBattleMgr(nBattleType)
	return self.m_tBattleMgrMap[nBattleType]
end

function CBattleCnt:MakeRoomID()
	self.m_nRoomInc = self.m_nRoomInc % 9999 + 1
	return self.m_nRoomInc 
end

goBattleCnt = goBattleCnt or CBattleCnt:new()