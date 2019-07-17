------客户端服务器------
--称谓数据请求
function Network.CltPBProc.AppellationDataReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    oRole.m_oAppellation:SyncAppellationData()
end

--装备称谓请求
function Network.CltPBProc.AppellationDisplayReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    oRole.m_oAppellation:DisplayReq(tData.nID)
end

--称谓属性激活请求
function Network.CltPBProc.AppellationAttrSetReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    oRole.m_oAppellation:AttrSetReq(tData.nID)
end

----------------Svr2Svr-----------------
