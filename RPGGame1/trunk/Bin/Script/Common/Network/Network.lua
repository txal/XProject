function Network:Init()
	self.oRemoteCall = CRemoteCall:new()
	self.oRemoteCall:Init()
	
	self.oClientCall = CClientCall:new()
	self.oClientCall:Init(CUtil:GetServiceID())
end

function Network:Release()
	self.oRemoteCall:Release()
	self.oClientCall:Release()
end