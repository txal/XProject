--后台指令
function Network.BsrCmdProc.BrowserReq(nCmd, nSrcServer, nSrcService, nTarSession, sData)
	local tData = cjson_raw.decode(sData)
	goBrowser:BrowserReq(nTarSession, tData)
end

--HTTP服务器收到请求
--@cConn 链接
--@sData 数据
--@nType 1:Get; 2:Post
--@sURI 目录
HttpRequestMessage = function(cConn, sData, nType, sURI)
	LuaTrace("HTTP request:", sData, nType, sURI)
	http.Response(cConn, sData)
end
