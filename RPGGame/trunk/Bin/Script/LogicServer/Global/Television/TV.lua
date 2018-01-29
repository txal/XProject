--电视广播
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CCTV:Ctor()
end

--广告发送
function CCTV:_TVSend(sCont)
	do return end --fix pd 屏蔽
	assert(sCont, "广告不存在")
	CmdNet.PBSrv2All("TVRet", {sCont=sCont})
end

goTV = goTV or CCTV:new()

