--@注意
--[[
json中的table要么是纯数组，要么是纯哈希表，
不能混合，否则会把table中所有key作为字符串类型decode。
--]]
function BsrCmdProc.BrowserReq(nCmd, nSrc, nSession, sData)
	local tDecode = cjson.decode(sData)
	print(sData, #tDecode, tDecode)

	local tTest = {1,2,3,a=1,b=2,c=3}
	local sTest = cjson.encode(tTest)
	CmdNet.Srv2Bsr(nSession, "BrowserRet", sTest)
end