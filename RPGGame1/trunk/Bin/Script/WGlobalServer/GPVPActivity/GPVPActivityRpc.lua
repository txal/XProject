
--------------------Svr2Svr------------------------
function Network.RpcSrv2Srv.GPVPActivityOpenNotify(nSrcServer, nSrcService, nTarSession, nActivityID, nServer)
	return goGPVPActivityNpcMgr:OnActivityOpen(nActivityID, nServer)
end

function Network.RpcSrv2Srv.GPVPActivityCloseNotify(nSrcServer, nSrcService, nTarSession, nActivityID, nServer)
	return goGPVPActivityNpcMgr:OnActivityClose(nActivityID, nServer)
end


