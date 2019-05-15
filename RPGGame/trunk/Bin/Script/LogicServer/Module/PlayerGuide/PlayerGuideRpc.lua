------客户端服务器------

--获取新手引导数据
function CltPBProc.PlayerGuideDataReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
	if not oRole then return end
    oRole.m_oGuide:SyncGuideData()
end

--设置新手引导数据
function CltPBProc.PlayerGuideSetReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
	if not oRole then return end
    oRole.m_oGuide:SetGuideDataReq(tData.nGuideID)
end


