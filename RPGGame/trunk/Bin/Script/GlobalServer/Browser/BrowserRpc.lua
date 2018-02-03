--@注意
--[[
json中的table要么是纯数组，要么是纯哈希表，
不能混合，否则会把table中所有key作为字符串类型decode。
--]]
function BsrCmdProc.BrowserReq(nCmd, nSrcServer, nSrcService, nSession, sData)
	local tData = cjson.decode(sData)
	goBrowser:BrowserReq(nSession, tData)
end