function CSceneDropMaker:Ctor(nConfID, _fnCallback, param)
	self.m_nConfID = nConfID
	self.m_nRefreshTick = nil
	self.m_fnCallback = _fnCallback
	self.m_param = param
end

function CSceneDropMaker:Start()
	if self.m_nRefreshTick then
		return
	end
	local tConf = ctSceneDropConf[self.m_nConfID]
	if not tConf then
		return
	end
	self.m_nRefreshTick = GlobalExport.RegisterTimer(tConf.nRefreshTime * 1000, function() self:DoRefresh() end)
end

function CSceneDropMaker:DoRefresh()
	local tConf = assert(ctSceneDropConf[self.m_nConfID])
	if tConf.bLoop then
		self.m_nRefreshTick = GlobalExport.RegisterTimer(tConf.nRefreshTime * 1000, function() self:DoRefresh() end)
	end
	if self.m_fnCallback then
		self.m_fnCallback(self.m_param, tConf)
	end
end

function CSceneDropMaker:Stop()
	if self.m_nRefreshTick then
		GlobalExport.CancelTimer(self.m_nRefreshTick)
		self.m_nRefreshTick = nil
	end
end