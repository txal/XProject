function CltPBProc.TestPack(nCmd, nSrc, nSession, tData)
	print("TestPack***",tData)
	CmdNet.PBSrv2Clt(nSession, "TestPack", tData)
end

