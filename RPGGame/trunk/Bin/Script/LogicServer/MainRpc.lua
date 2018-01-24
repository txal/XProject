function CltPBProc.TestPack(nCmd, nSrc, nSession, tData)
	local tSessionList = goPlayerMgr:GetSessionList(1)	
	print("TestPack***",tData, tSessionList)
	CmdNet.PBBroadcastExter(tSessionList, "TestPack", tData)
end