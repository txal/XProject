
--------------------Svr2Svr------------------------
function Srv2Srv.GPVEActivityOpenNotify(nSrcServer, nSrcService, nTarSession, nActivityID, nNpcID, nServer)
	return goGPVEActivityNpcMgr:OnActivityOpen(nActivityID, nNpcID, nServer)
end

function Srv2Srv.GPVEActivityCloseNotify(nSrcServer, nSrcService, nTarSession, nActivityID, nNpcID, nServer)
	return goGPVEActivityNpcMgr:OnActivityClose(nActivityID, nNpcID, nServer)
end


