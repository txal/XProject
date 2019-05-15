


------------------ Svr2Svr --------------
function Srv2Srv.SendNoticeAllReq(nSrcServer, nSrcService, nTarSession, sContent)
    local tGlobalList = goServerMgr:GetGlobalServiceList()
    for _, tConf in ipairs(tGlobalList) do 
        if tConf.nServer ~= gnWorldServerID and tConf.nServer > 0 then 
            GF.SendNotice(tConf.nServer, sContent)
        end
    end
end


