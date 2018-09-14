--滚屏信息
CRollingMsg = {}

function CRollingMsg:SendMSg(sCont, oPlayer)
	assert(sCont)
	if oPlayer then
		CmdNet.PBSrv2Clt(oPlayer:GetSession(), "RollingMsgNotify", {sCont=sCont})
	else
		CmdNet.PBSrv2All("RollingMsgNotify", {sCont=sCont})
	end
end

goRollingMSg = CRollingMsg