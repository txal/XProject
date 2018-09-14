function CltPBProc.CreateRoomReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local oGameMgr = goGameMgr:GetGame(gtGameType.eGDMJ)
	oGameMgr:CreateRoomReq(oPlayer, tData.nRoomType)
end

function CltPBProc.JoinRoomReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local tCurrGame = oPlayer.m_oGame:GetCurrGame()
	if tCurrGame.nRoomID > 0 then
		assert(tCurrGame.nGameType == gtGameType.eGDMJ)
		tData.nRoomID = tCurrGame.nRoomID
	end
	local oGameMgr = goGameMgr:GetGame(gtGameType.eGDMJ)
	oGameMgr:JoinRoomReq(oPlayer, tData.nRoomID)
end

function CltPBProc.LeaveRoomReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local tCurrGame = oPlayer.m_oGame:GetCurrGame()
	assert(tCurrGame.nGameType == gtGameType.eGDMJ)
	local oGameMgr = goGameMgr:GetGame(gtGameType.eGDMJ)
	oGameMgr:LeaveRoomReq(oPlayer)
end

function CltPBProc.PlayerReadyReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local tCurrGame = oPlayer.m_oGame:GetCurrGame()
	assert(tCurrGame.nGameType == gtGameType.eGDMJ)
	local oGameMgr = goGameMgr:GetGame(gtGameType.eGDMJ)
	oGameMgr:PlayerReadyReq(oPlayer)
end

function CltPBProc.DismissRoomReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local tCurrGame = oPlayer.m_oGame:GetCurrGame()
	assert(tCurrGame.nGameType == gtGameType.eGDMJ)
	local oGameMgr = goGameMgr:GetGame(gtGameType.eGDMJ)
	oGameMgr:DismissReq(oPlayer)
end

function CltPBProc.AgreeDismissRoomReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local tCurrGame = oPlayer.m_oGame:GetCurrGame()
	assert(tCurrGame.nGameType == gtGameType.eGDMJ)
	local oGameMgr = goGameMgr:GetGame(gtGameType.eGDMJ)
	oGameMgr:AgreeDismissReq(oPlayer)
end

function CltPBProc.OutMJReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local oRoom = oPlayer.m_oGame:GetRoom()
	if oRoom and oRoom:GameType() == gtGameType.eGDMJ then
		oRoom:OnUserOutMJ(oPlayer, tData.nOutMJ)
	end
end

function CltPBProc.PengReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local oRoom = oPlayer.m_oGame:GetRoom()	
	if oRoom and oRoom:GameType() == gtGameType.eGDMJ then
		oRoom:OnUserPeng(oPlayer)
	end
end

function CltPBProc.GangReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local oRoom = oPlayer.m_oGame:GetRoom()	
	if oRoom and oRoom:GameType() == gtGameType.eGDMJ then
		oRoom:OnUserGang(oPlayer, tData.nGangType)
	end
end

function CltPBProc.GangSelectReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local oRoom = oPlayer.m_oGame:GetRoom()	
	if oRoom and oRoom:GameType() == gtGameType.eGDMJ then
		oRoom:OnUserGangSelect(oPlayer, tData.nGangType, tData.nGangMJ)
	end
end

function CltPBProc.HuReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local oRoom = oPlayer.m_oGame:GetRoom()	
	if oRoom and oRoom:GameType() == gtGameType.eGDMJ then
		oRoom:OnUserHu(oPlayer, tData.nQiangGangMJ)
	end
end

function CltPBProc.GiveUpReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local oRoom = oPlayer.m_oGame:GetRoom()	
	if oRoom and oRoom:GameType() == gtGameType.eGDMJ then
		oRoom:OnUserGiveUp(oPlayer)
	end
end

--自由房
function CltPBProc.FreeRoomEnterReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local oGameMgr = goGameMgr:GetGame(gtGameType.eGDMJ)
	oGameMgr:FreeRoomEnterReq(oPlayer, tData.nDeskType)
end

function CltPBProc.FreeRoomMatchReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local oGameMgr = goGameMgr:GetGame(gtGameType.eGDMJ)
	oGameMgr:FreeRoomMatchReq(oPlayer, tData.nDeskType)
end

function CltPBProc.FreeRoomSwitchReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local oGameMgr = goGameMgr:GetGame(gtGameType.eGDMJ)
	oGameMgr:FreeRoomSwitchReq(oPlayer)
end

function CltPBProc.FreeRoomLeaveReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local oGameMgr = goGameMgr:GetGame(gtGameType.eGDMJ)
	oGameMgr:FreeRoomLeaveReq(oPlayer)
end

function CltPBProc.FreeRoomFullTiliReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local oGameMgr = goGameMgr:GetGame(gtGameType.eGDMJ)
	oGameMgr:FreeRoomFullTiliReq(oPlayer)
end

function CltPBProc.FreeRoomCancelAIReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local oRoom = oPlayer.m_oGame:GetRoom()
	if oRoom and oRoom:GameType() == gtGameType.eGDMJ then
		oRoom:CancelAIReq(oPlayer:GetCharID())
	end
end

function CltPBProc.FreeRoomFullTiliReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local oGameMgr = goGameMgr:GetGame(gtGameType.eGDMJ)
	oGameMgr:FreeRoomFullTiliReq(oPlayer)
end


--服务器内部
function Srv2Srv.FreeRoomMatchRet(nSrc, nSession, nTarRoomID, nDeskType, nCharID)
	local oGameMgr = goGameMgr:GetGame(gtGameType.eGDMJ)
	oGameMgr:FreeRoomMatchRet(nTarRoomID, nDeskType, nCharID)
end
