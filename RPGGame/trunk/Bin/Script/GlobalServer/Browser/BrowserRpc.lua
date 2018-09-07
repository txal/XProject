--后台指令
function BsrCmdProc.BrowserReq(nCmd, nSrcServer, nSrcService, nTarSession, sData)
	local tData = cjson.decode(sData)
	goBrowser:BrowserReq(nTarSession, tData)
end