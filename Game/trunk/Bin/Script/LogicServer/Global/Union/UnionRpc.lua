--通过玩家ID取战队
local function _GetUnionByCharID(sCharID)
	local oUnionPlayer = goUnionMgr:GetUnionPlayer(sCharID)
	if not oUnionPlayer or oUnionPlayer:Get("m_nUnionID") <= 0 then
		return
	end
	local oUnion = goUnionMgr:GetUnion(oUnionPlayer:Get("m_nUnionID"))
	if not oUnion then
		return
	end
	return oUnion
end

--请求战队信息
function CltPBProc.UnionDetailReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local sCharID = oPlayer:GetCharID()
	local oUnion = _GetUnionByCharID(sCharID)
	if not oUnion then
		return
	end
	oUnion:UnionDetailReq(oPlayer)
end

--战队列表请求
function CltPBProc.UnionListReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	goUnionMgr:UnionListReq(oPlayer, tData.sName, tData.nNum)
end

--申请加入战队请求
function CltPBProc.ApplyUnionReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local oUnion = goUnionMgr:GetUnion(tData.nID)
	if not oUnion then
		return
	end
	oUnion:ApplyUnionReq(oPlayer)
end

--创建战队请求
function CltPBProc.CreateUnionReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	goUnionMgr:CreateUnionReq(oPlayer, tData.nIcon, tData.sName, tData.sDeclaration)
end

--退出战队请求
function CltPBProc.ExitUnionReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local sCharID = oPlayer:GetCharID()
	local oUnion = _GetUnionByCharID(sCharID)
	if not oUnion then
		return
	end
	oUnion:ExitUnionReq(oPlayer)
end

--战队管理信息请求
function CltPBProc.UnionMgrInfoReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local sCharID = oPlayer:GetCharID()
	local oUnion = _GetUnionByCharID(sCharID)
	if not oUnion then
		return
	end
	oUnion:UnionMgrInfoReq(oPlayer)
end

--设置战队图标请求
function CltPBProc.SetUnionIconReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local sCharID = oPlayer:GetCharID()
	local oUnion = _GetUnionByCharID(sCharID)
	if not oUnion then
		return
	end
	oUnion:SetUnionIconReq(oPlayer, tData.nIcon)
end

--设置战队名称请求
function CltPBProc.SetUnionNameReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local sCharID = oPlayer:GetCharID()
	local oUnion = _GetUnionByCharID(sCharID)
	if not oUnion then
		return
	end
	oUnion:SetUnionNameReq(oPlayer, tData.sName)
end

--设置战队宣言请求
function CltPBProc.SetUnionDeclReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local sCharID = oPlayer:GetCharID()
	local oUnion = _GetUnionByCharID(sCharID)
	if not oUnion then
		return
	end
	oUnion:SetUnionDeclReq(oPlayer, tData.sDeclaration)
end

--审批设置
function CltPBProc.SetAutoJoinReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local sCharID = oPlayer:GetCharID()
	local oUnion = _GetUnionByCharID(sCharID)
	if not oUnion then
		return
	end
	oUnion:SetAutoJoinReq(oPlayer, tData.nAutoJoin)
end

--入队等级设置
function CltPBProc.SetJoinLevelReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local sCharID = oPlayer:GetCharID()
	local oUnion = _GetUnionByCharID(sCharID)
	if not oUnion then
		return
	end
	oUnion:SetJoinLevelReq(oPlayer, tData.nJoinLevel)
end

--扩展战队人数
function CltPBProc.ExtendMembersReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local sCharID = oPlayer:GetCharID()
	local oUnion = _GetUnionByCharID(sCharID)
	if not oUnion then
		return
	end
	oUnion:ExtendMembersReq(oPlayer)
end

--申请列表请求
function CltPBProc.ApplyListReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local sCharID = oPlayer:GetCharID()
	local oUnion = _GetUnionByCharID(sCharID)
	if not oUnion then
		return
	end
	oUnion:ApplyListReq(oPlayer)
end
--接受申请
function CltPBProc.AcceptApplyReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local sCharID = oPlayer:GetCharID()
	local oUnion = _GetUnionByCharID(sCharID)
	if not oUnion then
		return
	end
	oUnion:AcceptApplyReq(oPlayer, tData.sCharID)
end
--拒绝申请
function CltPBProc.RefuseApplyReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local sCharID = oPlayer:GetCharID()
	local oUnion = _GetUnionByCharID(sCharID)
	if not oUnion then
		return
	end
	oUnion:RefuseApplyReq(oPlayer, tData.sCharID)
end

--队员列表请求
function CltPBProc.MemberListReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local sCharID = oPlayer:GetCharID()
	local oUnion = _GetUnionByCharID(sCharID)
	if not oUnion then
		return
	end
	oUnion:MemberListReq(oPlayer)
end

--移除队员
function CltPBProc.KickUnionMemberReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local sCharID = oPlayer:GetCharID()
	local oUnion = _GetUnionByCharID(sCharID)
	if not oUnion then
		return
	end
	oUnion:KickMemberReq(oPlayer, tData.sCharID)
end

--日志列表请求
function CltPBProc.LogListReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local sCharID = oPlayer:GetCharID()
	local oUnion = _GetUnionByCharID(sCharID)
	if not oUnion then
		return
	end
	oUnion:LogListReq(oPlayer)
end

--任命职位请求
function CltPBProc.AppointReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local sCharID = oPlayer:GetCharID()
	local oUnion = _GetUnionByCharID(sCharID)
	if not oUnion then
		return
	end
	oUnion:AppointReq(oPlayer, tData.sCharID, tData.nPos)
end
