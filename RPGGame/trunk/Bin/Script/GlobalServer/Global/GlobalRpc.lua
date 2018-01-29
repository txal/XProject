function SrvCmdProc.OnServiceClose(nCmd, nSrc, nSession, nService, nServerID)
	print("SrvCmdProc.OnServiceClose***", nService, nServerID)
	if not gtNetConf.tGateService[nService] then
		return
	end
	OnExitServer()
end
