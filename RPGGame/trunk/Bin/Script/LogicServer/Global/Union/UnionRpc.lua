--请求联盟信息
function CltPBProc.UnionDetailReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end

	local nCharID = oPlayer:GetCharID()
	local oUnion = goUnionMgr:GetUnionByCharID(nCharID)
	if not oUnion then return end

	oUnion:UnionDetailReq(oPlayer)
end

--联盟列表请求
function CltPBProc.UnionListReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end

	goUnionMgr:UnionListReq(oPlayer, tData.sUnionKey, tData.bNotFull)
end

--申请加入联盟请求
function CltPBProc.ApplyUnionReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end

	local oUnion = goUnionMgr:GetUnion(tData.nID)
	if not oUnion then return end

	oUnion:ApplyUnionReq(oPlayer)
end

--创建联盟请求
function CltPBProc.CreateUnionReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end

	goUnionMgr:CreateUnionReq(oPlayer, tData.sName, tData.sNotice)
end

--退出联盟请求
function CltPBProc.ExitUnionReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end

	local nCharID = oPlayer:GetCharID()
	local oUnion = goUnionMgr:GetUnionByCharID(nCharID)
	if not oUnion then return end

	oUnion:ExitUnionReq(oPlayer)
end

--设置联盟宣言请求
function CltPBProc.SetUnionDeclReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end

	local nCharID = oPlayer:GetCharID()
	local oUnion = goUnionMgr:GetUnionByCharID(nCharID)
	if not oUnion then return end

	oUnion:SetUnionDeclReq(oPlayer, tData.sDeclaration)
end

--审批设置
function CltPBProc.SetAutoJoinReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end

	local nCharID = oPlayer:GetCharID()
	local oUnion = goUnionMgr:GetUnionByCharID(nCharID)
	if not oUnion then return end

	oUnion:SetAutoJoinReq(oPlayer, tData.nAutoJoin)
end

--申请列表请求
function CltPBProc.ApplyListReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end

	local nCharID = oPlayer:GetCharID()
	local oUnion = goUnionMgr:GetUnionByCharID(nCharID)
	if not oUnion then return end

	oUnion:ApplyListReq(oPlayer)
end
--接受申请
function CltPBProc.AcceptApplyReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end

	local nCharID = oPlayer:GetCharID()
	local oUnion = goUnionMgr:GetUnionByCharID(nCharID)
	if not oUnion then return end

	oUnion:AcceptApplyReq(oPlayer, tData.nCharID)
end
--拒绝申请
function CltPBProc.RefuseApplyReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end

	local nCharID = oPlayer:GetCharID()
	local oUnion = goUnionMgr:GetUnionByCharID(nCharID)
	if not oUnion then return end

	oUnion:RefuseApplyReq(oPlayer, tData.nCharID)
end

--队员列表请求
function CltPBProc.MemberListReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end

	local nCharID = oPlayer:GetCharID()
	local oUnion = goUnionMgr:GetUnionByCharID(nCharID)
	if not oUnion then return end

	oUnion:MemberListReq(oPlayer)
end

--移除队员
function CltPBProc.KickUnionMemberReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end

	local nCharID = oPlayer:GetCharID()
	local oUnion = goUnionMgr:GetUnionByCharID(nCharID)
	if not oUnion then return end

	oUnion:KickMemberReq(oPlayer, tData.nCharID)
end

--任命职位请求
function CltPBProc.AppointReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end

	local nCharID = oPlayer:GetCharID()
	local oUnion = goUnionMgr:GetUnionByCharID(nCharID)
	if not oUnion then return end
	
	oUnion:AppointReq(oPlayer, tData.nCharID, tData.nPos)
end

--联盟升级请求
function CltPBProc.UnionUpgradeReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end

	local nCharID = oPlayer:GetCharID()
	local oUnion = goUnionMgr:GetUnionByCharID(nCharID)
	if not oUnion then return end
	
	oUnion:UpgradeReq(oPlayer)
end

--成员详细信息请求
function CltPBProc.MemberDetailReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end

	local nCharID = oPlayer:GetCharID()
	local oUnion = goUnionMgr:GetUnionByCharID(nCharID)
	if not oUnion then return end
	
	oUnion:MemberDetailReq(oPlayer, tData.nCharID)
end

--随机加入联盟
function CltPBProc.JoinRandUnionReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end

	goUnionMgr:JoinRandUnionReq(oPlayer)
end


--联盟建设情况请求
function CltPBProc.UnionBuildInfoReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end

	local nCharID = oPlayer:GetCharID()
	local oUnion = goUnionMgr:GetUnionByCharID(nCharID)
	if not oUnion then return end

	oUnion:BuildInfoReq(oPlayer)
end

--联盟建设请求
function CltPBProc.UnionBuildReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end

	local nCharID = oPlayer:GetCharID()
	local oUnion = goUnionMgr:GetUnionByCharID(nCharID)
	if not oUnion then return end

	oUnion:BuildReq(oPlayer, tData.nBuildID)
end

--联盟兑换列表请求
function CltPBProc.UnionExchangeListReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end

	local nCharID = oPlayer:GetCharID()
	local oUnion = goUnionMgr:GetUnionByCharID(nCharID)
	if not oUnion then return end

	oUnion:ExchangeListReq(oPlayer)
end

--联盟兑换请求
function CltPBProc.UnionExchangeReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end

	local nCharID = oPlayer:GetCharID()
	local oUnion = goUnionMgr:GetUnionByCharID(nCharID)
	if not oUnion then return end

	oUnion:ExchangeReq(oPlayer, tData.nID)
end

function CltPBProc.UnionPartyListReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end

	local nCharID = oPlayer:GetCharID()
	local oUnion = goUnionMgr:GetUnionByCharID(nCharID)
	if not oUnion then return end

	oUnion.m_oUnionParty:PartyListReq(oPlayer)
end

function CltPBProc.UnionPartyRankingReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end

	local nCharID = oPlayer:GetCharID()
	local oUnion = goUnionMgr:GetUnionByCharID(nCharID)
	if not oUnion then return end

	oUnion.m_oUnionParty:RankingReq(oPlayer, tData.nID)
end

function CltPBProc.UnionPartyOpenReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end

	local nCharID = oPlayer:GetCharID()
	local oUnion = goUnionMgr:GetUnionByCharID(nCharID)
	if not oUnion then return end

	oUnion.m_oUnionParty:OpenPartyReq(oPlayer, tData.nID, tData.nType)
end

function CltPBProc.UnionPartyBossReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end

	local nCharID = oPlayer:GetCharID()
	local oUnion = goUnionMgr:GetUnionByCharID(nCharID)
	if not oUnion then return end

	oUnion.m_oUnionParty:BossInfoReq(oPlayer, tData.nPartyID)
end

function CltPBProc.UnionPartyMCListReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end

	local nCharID = oPlayer:GetCharID()
	local oUnion = goUnionMgr:GetUnionByCharID(nCharID)
	if not oUnion then return end

	oUnion.m_oUnionParty:MCListReq(oPlayer, tData.nID)
end

function CltPBProc.UnionPartyAddMCReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end

	local nCharID = oPlayer:GetCharID()
	local oUnion = goUnionMgr:GetUnionByCharID(nCharID)
	if not oUnion then return end

	oUnion.m_oUnionParty:AddMCReq(oPlayer, tData.nMCID)
end

function CltPBProc.UnionPartyRemoveMCReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end

	local nCharID = oPlayer:GetCharID()
	local oUnion = goUnionMgr:GetUnionByCharID(nCharID)
	if not oUnion then return end

	oUnion.m_oUnionParty:RemoveMCReq(oPlayer, tData.nMCID)
end

function CltPBProc.UnionPartyRecoverMCReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end

	local nCharID = oPlayer:GetCharID()
	local oUnion = goUnionMgr:GetUnionByCharID(nCharID)
	if not oUnion then return end

	oUnion.m_oUnionParty:RecoverMCReq(oPlayer, tData.nMCID)
end

function CltPBProc.UnionPartyStartBattleReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end

	local nCharID = oPlayer:GetCharID()
	local oUnion = goUnionMgr:GetUnionByCharID(nCharID)
	if not oUnion then return end

	oUnion.m_oUnionParty:StartBattleReq(oPlayer, tData.nID, tData.bAuto)
end

function CltPBProc.UnionMiracleListReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end

	local nCharID = oPlayer:GetCharID()
	local oUnion = goUnionMgr:GetUnionByCharID(nCharID)
	if not oUnion then return end

	oUnion.m_oUnionMiracle:MiracleListReq(oPlayer)
end

function CltPBProc.UnionMiracleDonateReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end

	local nCharID = oPlayer:GetCharID()
	local oUnion = goUnionMgr:GetUnionByCharID(nCharID)
	if not oUnion then return end

	oUnion.m_oUnionMiracle:DonateReq(oPlayer, tData.nMID, tData.nDID)
end

function CltPBProc.UnionDonateDetailReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end

	local nCharID = oPlayer:GetCharID()
	local oUnion = goUnionMgr:GetUnionByCharID(nCharID)
	if not oUnion then return end

	oUnion.m_oUnionMiracle:DonateDetailReq(oPlayer)
end
