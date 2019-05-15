--客户端->服务器

function CltPBProc.ArtifactListReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oArtifact:ArtifactListReq()
end

function CltPBProc.ArtifactUpgradeReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oArtifact:ArtifactUpgradeReq(tData.nID, tData.bFlag)
end

function CltPBProc.ArtifactAscendingStarReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oArtifact:ArtifactAscendingStarReq(tData.nID)
end

function CltPBProc.ArtifactAddExpReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oArtifact:ArtifactAddExpReq(tData.nArtifactID, tData.tItemList)
end

function CltPBProc.ArtifactUseShapeReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oArtifact:ArtifactUseShapeReq(tData.nArtifactID)
end

function CltPBProc.ArtifactCallUseShapeReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oArtifact:ArtifactCallUseShapeReq(tData.nArtifactID)
end

function CltPBProc.ArtifactUseReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oArtifact:USEArtivaion(tData.nArtifactID, tData.nType)
end
