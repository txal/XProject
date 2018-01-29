function Srv2Srv.OnPlayerOnline(nSrc, nSession, tPlayer)
	goGPlayerMgr:PlayerOnline(tPlayer)
end

function Srv2Srv.OnPlayerOffline(nSrc, nSession)
	goGPlayerMgr:PlayerOffline(nSession)
end