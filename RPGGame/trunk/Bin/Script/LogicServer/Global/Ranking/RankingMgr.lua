--排行榜管理器
local nAutoSaveTick = 5*60

function CRankingMgr:Ctor()
	self.m_nSaveTick = nil
	self.m_tRankingMap = {}
	self:Init()
end

function CRankingMgr:Init()
	self.m_oJZRanking = CJZRanking:new(gtRankingDef.eJZRanking) --建筑加成排行
	self.m_oGLRanking = CGLRanking:new(gtRankingDef.eGLRanking) --国力排行榜
	self.m_oHZRanking = CHZRanking:new(gtRankingDef.eHZRanking) --鼓励排行榜
	self.m_oSLRanking = CSLRanking:new(gtRankingDef.eSLRanking) --势力排行榜
	self.m_oQMRanking = CQMRanking:new(gtRankingDef.eQMRanking) --亲密度排行榜
	self.m_oNLRanking = CNLRanking:new(gtRankingDef.eNLRanking) --能力排行榜
	self.m_oCDRanking = CCDRanking:new(gtRankingDef.eCDRanking) --才德排行榜
	self.m_oWWRanking = CWWRanking:new(gtRankingDef.eWWRanking) --威望排行榜
	self.m_oZJRanking = CZJRanking:new(gtRankingDef.eZJRanking) --战绩排行榜
	self.m_oUGLRanking = CUGLRanking:new(gtRankingDef.eUGLRanking) 			--联盟国力排行榜
	self.m_oCZDQRanking = CCZDQRanking:new(gtRankingDef.eCZDQRanking) 		--追讨赔款排行榜
	self.m_oDupRanking = CDupRanking:new(gtRankingDef.eDupRanking) 			--副本排行
	self.m_oUnExpRanking = CUnExpRanking:new(gtRankingDef.eUnExpRanking) 	--联盟经验榜
	self.m_oZRQGRanking = CZRQGRanking:new(gtRankingDef.eZRQGRanking)		--造人排行榜
	self.m_oMCRanking = CMCRanking:new(gtRankingDef.eMCRanking)				--名臣总属性排行
	self.m_oPartyRanking = CPartyRanking:new(gtRankingDef.ePartyRanking)	--宴会积分排行
	-- self.m_oGDRanking = CGDRanking:new(gtRankingDef.eGDRanking)	--宫斗排行榜				

	self.m_tRankingMap[gtRankingDef.eJZRanking] = self.m_oJZRanking
	self.m_tRankingMap[gtRankingDef.eGLRanking] = self.m_oGLRanking
	self.m_tRankingMap[gtRankingDef.eHZRanking] = self.m_oHZRanking
	self.m_tRankingMap[gtRankingDef.eSLRanking] = self.m_oSLRanking
	self.m_tRankingMap[gtRankingDef.eQMRanking] = self.m_oQMRanking
	self.m_tRankingMap[gtRankingDef.eNLRanking] = self.m_oNLRanking
	self.m_tRankingMap[gtRankingDef.eCDRanking] = self.m_oCDRanking
	self.m_tRankingMap[gtRankingDef.eWWRanking] = self.m_oWWRanking
	self.m_tRankingMap[gtRankingDef.eZJRanking] = self.m_oZJRanking
	self.m_tRankingMap[gtRankingDef.eUGLRanking] = self.m_oUGLRanking
	self.m_tRankingMap[gtRankingDef.eCZDQRanking] = self.m_oCZDQRanking
	self.m_tRankingMap[gtRankingDef.eDupRanking] = self.m_oDupRanking
	self.m_tRankingMap[gtRankingDef.eUnExpRanking] = self.m_oUnExpRanking
	self.m_tRankingMap[gtRankingDef.eZRQGRanking] = self.m_oZRQGRanking
	self.m_tRankingMap[gtRankingDef.eMCRanking] = self.m_oMCRanking
	self.m_tRankingMap[gtRankingDef.ePartyRanking] = self.m_oPartyRanking
	self.m_tRankingMap[gtRankingDef.eGDRanking] = self.m_oGDRanking

end

--加载数据
function CRankingMgr:LoadData()
	print("CRankingMgr:LoadData***")
	for _, oRanking in pairs(self.m_tRankingMap) do
		oRanking:LoadData()
	end
	self:AutoSave()
end

function CRankingMgr:AutoSave()
	self.m_nSaveTick = goTimerMgr:Interval(nAutoSaveTick, function() self:SaveData() end)
end

--保存数据
function CRankingMgr:SaveData()
	print("CRankingMgr:SaveData***")
	for _, oRanking in pairs(self.m_tRankingMap) do
		oRanking:SaveData()
	end

end

--释放
function CRankingMgr:OnRelease()
	goTimerMgr:Clear(self.m_nSaveTick)
	self.m_nSaveTick = nil

	for _, oRanking in pairs(self.m_tRankingMap) do
		oRanking:OnRelease()
	end
	
end

--取排行榜
function CRankingMgr:GetRanking(nID)
	return self.m_tRankingMap[nID]
end

goRankingMgr = goRankingMgr or CRankingMgr:new()
