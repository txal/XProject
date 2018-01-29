function CltPBProc.LoginReq(nCmd, nSrc, nSession, tData)
	print("CltPBProc.LoginReq***", tData)
	local sAccount = string.Trim(tData.sAccount or "")
	local sPassword = string.Trim(tData.sPassword or "")
	if sAccount == "" or sPassword == "" then
		LuaTrace("账号或密码为空")
		return CPlayer:Tips("账号或密码为空", nSession)
	end
	GF.CheckNameLen(sAccount, nMAX_NAMELEN)
	GF.CheckNameLen(sPassword, nMAX_NAMELEN)
	local nSource = tData.nSource or 0
    goPlayerMgr:Login(nSession, sAccount, sPassword, nSource)
end

function CltPBProc.LoginoutReq(nCmd, nSrc, nSession, tData)
    goPlayerMgr:Logout(nSession)
end

function CltPBProc.CreateRoleReq(nCmd, nSrc, nSession, tData)
	local sAccount = string.Trim(tData.sAccount or "")
	local sPassword = string.Trim(tData.sPassword or "")
	local sCharName = string.Trim(tData.sCharName or "")
	if sAccount =="" or sPassword == "" or sCharName == "" then
		LuaTrace("账号或密码或角色名为空")
		return CPlayer:Tips("账号或密码或角色名为空", nSession)
	end
	GF.CheckNameLen(sAccount, nMAX_NAMELEN)
	GF.CheckNameLen(sPassword, nMAX_NAMELEN)
	
	local nNameLen = string.len(tData.sCharName)
	if nNameLen <= 0 or nNameLen > 6*3 then
		LuaTrace("昵称长度非法")
		return CPlayer:Tips("昵称长度非法", nSession)
	end
	
	local nSource = tData.nSource or 0
    goPlayerMgr:CreateRole(nSession, sAccount, sPassword, sCharName, nSource)
end

--聊天中玩家综合信息
function CltPBProc.PlayerInfoReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end

	local nCharID = tData.nCharID
	local oTarPlayer = goPlayerMgr:GetPlayerByCharID(nCharID)
	if not oTarPlayer then
		return oPlayer:Tips("目标玩家不在线")
	end
	local tInfo = oTarPlayer:GetInfo()
    CmdNet.PBSrv2Clt(nSession, "PlayerInfoRet", {tInfo=tInfo})
end

--排行榜中玩家综合信息
function CltPBProc.RankingPlayerInfoReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end

	local tInfo = oPlayer:GetInfo()
    CmdNet.PBSrv2Clt(nSession, "RankingPlayerInfoRet", {tInfo=tInfo})
end

--玩家改名
function CltPBProc.PlayerModNameReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer:ModName(tData.sCharName)
end

--登出
function CltPBProc.LogoutReq(nCmd, nSrc, nSession, tData)
	goPlayerMgr:Logout(nSession)
end

--国家进阶
function CltPBProc.UpgradeReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer:UpgradeReq()
end

---------------服务器内部----------------
