--公告管理器信息
function CNoticeMgr:Ctor()
end

--滚屏公告(滚动1次)
function CNoticeMgr:Scroll(sCont, nSession)
	assert(sCont)
	if nSession then
		CmdNet.PBSrv2Clt(nSession, "ScrollMsgRet", {sCont=sCont})
	else
		CmdNet.PBSrv2All("ScrollMsgRet", {sCont=sCont})
	end
end

--Tips
function CNoticeMgr:Tips(sCont, nSession)
    CmdNet.PBSrv2Clt(nSession, "TipsMsgRet", {sCont=sCont})
 end


goNoticeMgr = goNoticeMgr or CNoticeMgr:new()