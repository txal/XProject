function Network:Init()
	self.oRemoteCall = CRemoteCall:new()
	self.oRemoteCall:Init()
	
	self.oClientCall = CClientCall:new()
	self.oClientCall:Init(C)
end

function Network:Release()
	self.oRemoteCall:Release()
	self.oClientCall:Release()
end

--远程调用封装,不需要回调fnCallBack传nil
function Network:RMCall("sFunc", fnCallBack, nServerID, nServiceID, nSessionID, ...)
    assert(nServiceID > 0, "服务ID错误")
    nSessionID = nSessionID or 0
    if fnCallBack then
        self.oRemoteCall:CallWait(sFunc, fnCallBack, nServerID, nServiceID, nSessionID, ...)
    else
        self.oRemoteCall:Call(sFunc, nServerID, nServiceID, nSessionID, ...)
    end
end

--客户端远程调用封装,不需要回调fnCallBack传nil
function Network:CLCall(sFunc, fnCallBack, oRole, tMsg)
    if fnCallBack then
        self.oClientCall:CallWait(sFunc, fnCallBack, oRole, tMsg)
    else
        self.oClientCall:Call(sFunc, oRole, tMsg)
    end
end
