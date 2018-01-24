function CBattleMgr:Ctor()
	self.m_tBattleMgrMap = {}
	self.m_nRoomInc = 0
end

function CBattleMgr:RegBattleMgr()
	self.m_tBattleMgrMap[gtBattleType.eBugStorm] = CBugStormMgr:new()
	self.m_tBattleMgrMap[gtBattleType.eBugHole] = CBugHoleMgr:new()
end

function CBattleMgr:GetBattleMgr(nBattleType)
	return self.m_tBattleMgrMap[nBattleType]
end

function CBattleMgr:MakeRoomID()
	self.m_nRoomInc = self.m_nRoomInc % 9999 + 1
	return self.m_nRoomInc 
end

goBattleMgr = goBattleMgr or CBattleMgr:new()