
--------------------Svr2Svr------------------------
function Srv2Srv.GPVPActivityOpenNotify(nSrcServer, nSrcService, nTarSession, nActivityID, nServer)
	return goGPVPActivityNpcMgr:OnActivityOpen(nActivityID, nServer)
end

function Srv2Srv.GPVPActivityCloseNotify(nSrcServer, nSrcService, nTarSession, nActivityID, nServer)
	return goGPVPActivityNpcMgr:OnActivityClose(nActivityID, nServer)
end


