local nMaxNameLen = 256
function CltPBProc.LoginReq(nCmd, nSrc, nSession, tData)
	local sAccount = string.Trim(tData.sAccount or "")
	local sPassword = string.Trim(tData.sPassword or "")
	local sImgURL = tData.sImgURL or ""
	assert(sAccount ~= "" and  sPassword ~= "", "账号或密码不能为空")
	GF.CheckNameLen(sAccount, nMaxNameLen)
	GF.CheckNameLen(sPassword, nMaxNameLen)
	GF.CheckNameLen(sImgURL, nMaxNameLen)
    goPlayerMgr:Login(nSession, sAccount, sPassword, sImgURL)
end

function CltPBProc.LoginoutReq(nCmd, nSrc, nSession, tData)
    goPlayerMgr:Logout(nSession)
end

function CltPBProc.CreateRoleReq(nCmd, nSrc, nSession, tData)
	local sAccount = string.Trim(tData.sAccount or "")
	local sPassword = string.Trim(tData.sPassword or "")
	local sCharName = string.Trim(tData.sCharName or "")
	assert(sAccount ~="" and sPassword ~= "" and sCharName ~= "", "参数不能为空")
	GF.CheckNameLen(sAccount, nMaxNameLen)
	GF.CheckNameLen(sPassword, nMaxNameLen)
	GF.CheckNameLen(sCharName, nMaxNameLen)
    goPlayerMgr:CreateRole(nSession, sAccount, sPassword, sCharName)
end

function CltPBProc.LogoutReq(nCmd, nSrc, nSession, tData)
    goPlayerMgr:Logout(nSession)
end


---------------服务器内部----------------
--GLOBAL服请求玩家状态
function Srv2Srv.GlobalPlayerStateReq(nSrc, nSession, nCharID)
	local oPlayer
	if nSession > 0 then
		oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	elseif nCharID ~= 0 then
		oPlayer = goPlayerMgr:GetPlayerByCharID(nCharID)
	end
	print("Srv2Srv.GlobalPlayerStateReq***", nSrc, nSession, nCharID)
	if not oPlayer then
		return
	end
	Srv2Srv.OnPlayerOnline(gtNetConf:GlobalService()
		, oPlayer:GetSession()
		, oPlayer:GetCharID()
		, oPlayer:GetName()
		, GlobalExport:GetServiceID()
	)
end

--切换逻辑服请求
function Srv2Srv.SwitchLogicServerReq(nSrc, nSession, tAccount)
	goPlayerMgr:Login(nSession, tAccount.sAccount, tAccount.sPassword)
end