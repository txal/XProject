function Clt2Srv.Test(nSrc, nSession, ...)
	Srv2Clt.Test(nSession, ...)
end

function CltCmdProc.Ping(nCmd, nSrc, nSession)
	CmdNet.Srv2Clt(nSession, "Ping")
end
