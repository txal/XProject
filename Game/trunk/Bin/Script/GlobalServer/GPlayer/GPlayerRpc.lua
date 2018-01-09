function Srv2Srv.OnPlayerOnline(nSrc, nSession, nCharID, sCharName, nLogicService, sPlatform, sChannel)
	print("OnPlayerOnline***", nSrc, nSession, nCharID, sCharName, nLogicService, sPlatform, sChannel)
	goGPlayerMgr:CreatePlayer(nSession, nCharID, sCharName, nLogicService, sPlatform, sChannel)
end

function Srv2Srv.OnPlayerOffline(nSrc, nSession)
	goGPlayerMgr:RemovePlayer(nSession)
end