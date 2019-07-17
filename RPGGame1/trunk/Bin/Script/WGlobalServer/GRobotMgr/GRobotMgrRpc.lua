

function Network.RpcSrv2Srv.PVPActCreateRobotReq(nSrcServer, nSrcService, nTarSession, tParamList)
    if not tParamList or #tParamList <= 0 then 
        return 
    end

    for _, tParam in ipairs(tParamList) do 
        local nMinLevel = tParam.nMinLevel
        local nMaxLevel = tParam.nMaxLevel or #ctRoleLevelConf
        local nTarServer = tParam.nServer >= 10000 and 0 or tParam.nServer
        local nDupMixID = tParam.nDupMixID
        local tRoleConfID = tParam.tRoleConfID
        local nRoleConfID = 0
        if #tRoleConfID >= 1 then 
            nRoleConfID = tRoleConfID[math.random(#tRoleConfID)]
        end
        goGRobotMgr:CreateRobot(nTarServer, nMinLevel, nMaxLevel, nRoleConfID, gtRobotType.ePVPAct, nDupMixID)
    end
end

function Network.RpcSrv2Srv.AddRole2RobotPoolReq(nSrcServer, nSrcService, nTarSession, nRoleID)
    assert(nRoleID and nRoleID > 0)
    -- print(string.format(">>>>> 通知添加机器人玩家池(%d) <<<<<<", nRoleID))
    local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
    if not oRole or oRole:IsOnline() then 
        return 
    end
    goGRobotMgr:AddToRoleMatchPool(nRoleID, oRole:GetLevel())
end

function Network.RpcSrv2Srv.RemoveRoleFromRobotPoolReq(nSrcServer, nSrcService, nTarSession, nRoleID)
    assert(nRoleID and nRoleID > 0)
    -- print(string.format(">>>>> 通知删除机器人玩家池(%d) <<<<<<", nRoleID))
    goGRobotMgr:RemoveFromMatchPool(nRoleID)
end

function Network.RpcSrv2Srv.GuaJiCreateRobotReq(nSrcServer, nSrcService, nTarSession, tParamList)
    if not tParamList or #tParamList <= 0 then 
        return 
    end
    for _, tData in ipairs(tParamList) do
        local nMinLevel = tData.nMinLevel
        local nMaxLevel = tData.nMaxLevel or #ctRoleLevelConf
        local nTarServer = tData.nServer >= 10000 and 0 or tData.nServer
        local nDupMixID = tData.nDupMixID
        goGRobotMgr:CreateRobot(nTarServer, nMinLevel, nMaxLevel, 0, gtRobotType.eNormal, nDupMixID)
    end
end
