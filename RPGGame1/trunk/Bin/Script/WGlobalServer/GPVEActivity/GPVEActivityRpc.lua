
--------------------Svr2Svr------------------------
function Network.RpcSrv2Srv.GPVEActivityOpenNotify(nSrcServer, nSrcService, nTarSession, nActivityID, nNpcID, nServer)
	return goGPVEActivityNpcMgr:OnActivityOpen(nActivityID, nNpcID, nServer)
end

function Network.RpcSrv2Srv.GPVEActivityCloseNotify(nSrcServer, nSrcService, nTarSession, nActivityID, nNpcID, nServer)
	return goGPVEActivityNpcMgr:OnActivityClose(nActivityID, nNpcID, nServer)
end


