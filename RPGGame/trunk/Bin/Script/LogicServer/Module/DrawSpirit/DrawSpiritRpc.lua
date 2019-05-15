------客户端服务器------
--摄魂数据请求
function CltPBProc.DrawSpiritDataReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    oRole.m_oDrawSpirit:SyncDrawSpiritData()
end

--当前灵气数量请求
function CltPBProc.DrawSpiritCurSpiritNumReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    oRole.m_oDrawSpirit:SyncSpiritNum()
end

--摄魂升级请求
function CltPBProc.DrawSpiritLevelUpReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
   oRole.m_oDrawSpirit:OnKeyLevelUpReq()
end

--摄魂灵气消耗等级调整请求
function CltPBProc.DrawSpiritSetTriggerLevelReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    oRole.m_oDrawSpirit:SetTriggerLevelReq(tData.nTriggerLevel)
end

--摄魂炼魂信息请求
function CltPBProc.DrawSpiritLianhunInfoReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
   oRole.m_oDrawSpirit:SyncLianhunData()
end

--摄魂炼魂升级请求
function CltPBProc.DrawSpiritLianhunLevelUpReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
   oRole.m_oDrawSpirit:LianhunLevelUpReq()
end

--摄魂法阵信息请求
function CltPBProc.DrawSpiritFazhenInfoReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
   oRole.m_oDrawSpirit:SyncFazhenData()
end

--摄魂法阵升级请求
function CltPBProc.DrawSpiritFazhenLevelUpReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
   oRole.m_oDrawSpirit:FazhenLevelUpReq()
end

----------------Svr2Svr-----------------



