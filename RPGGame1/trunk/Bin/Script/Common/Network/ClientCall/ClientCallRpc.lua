--客户端确认(选择了选项)请求
function Network.CltPBProc.ConfirmReactReq(nCmd, nServer, nService, nSession, tData)
	goClientCall:OnCallRet(nServer, nSession, tData.nCallID, tData)
end

function Network.CltPBProc.ItemConfirmReactReq(nCmd, nServer, nService, nSession, tData)
	goClientCall:OnCallRet(nServer, nSession, tData.nCallID, tData)
end
