--客户端-服务器
function CltPBProc.RoleEnterSceneReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    print("CltPBProc.RoleEnterSceneReq***", nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end

    local oCurrDupObj = oRole:GetCurrDupObj()
    local tCurrDupConf = oCurrDupObj and oCurrDupObj:GetConf()

    local tTarDupConf = ctDupConf[GF.GetDupID(tData.nDupMixID)]
    local nTarDupMixID = tData.nDupMixID
    local nPosX = tData.nPosX < 0 and tTarDupConf.tBorn[1][1] or tData.nPosX
    local nPosY = tData.nPosY < 0 and tTarDupConf.tBorn[1][2] or tData.nPosY
    if not oRole:CheckTeamOp() then
        return print(oRole:GetName(), "队伍跟随中，屏蔽队员切换场景请求，会出现队员先切换场景导致暂离情况")
    end

    -- if (tCurrDupConf and tCurrDupConf.nType == CDupBase.tType.eDup) 
    --     and (tCurrDupConf.nBattleType ~= tTarDupConf.nBattleType) 
    --     and not table.InArray(tTarDupConf.nBattleType, tCurrDupConf.tHallBattleType) then
    --     --策划要求副本中只能通过副本出口离开，此拦截副本中切换场景请求
    --     --return oRole:Tips("离开副本，请点击右上角退出按钮")
    --     local tMsg = {sCont="是否确定离开当前副本(客户端请求)？", tOption={"取消", "确定"}, nTimeOut=30}
    --     goClientCall:CallWait("ConfirmRet", function(tData)
    --         if tData.nSelIdx == 1 then
    --             return
    --         elseif tData.nSelIdx == 2 then
    --             --oRole:EnterLastCity()
    --             oRole:EnterScene(nTarDupMixID, nPosX, nPosY, -1, tTarDupConf.nFace)
    --         end
    --     end, oRole, tMsg)
    --     --goBattleDupMgr:LeaveBattleDupReq(oRole)
    -- else 
    --     oRole:EnterScene(tData.nDupMixID, nPosX, nPosY, -1, tTarDupConf.nFace)
    -- end
    -- oRole:EnterScene(tData.nDupMixID, nPosX, nPosY, -1, tTarDupConf.nFace)
    goDupMgr:EnterDupReq(oRole, tData.nDupMixID, nPosX, nPosY, -1, tTarDupConf.nFace)
end

function CltPBProc.RoleLeaveSceneReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    -- 临时屏蔽，对于客户端而言，退出场景是从属于进入某个场景事件的，不能独立执行退出场景
    local oRole = goPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    -- goDupMgr:LeaveScene(tData.nDupMixID)
    oRole:EnterLastCity()
end

------服务器内部
function Srv2Srv.DupRoleViewListReq(nSrcServer, nSrcService, nTarSession, nRoleID)
    local oRole = goPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then return end
    local tRoleList = goDupMgr:DupRoleViewListReq(oRole)
    return tRoleList
end

function Srv2Srv.CreateDup(nSrcServer,nSrcService,nTarSession,nDupID,tParam)
    local oDup = goDupMgr:CreateDup(nDupID)
    if tParam.nNoAutoCollected then
        oDup:SetAutoCollected(false)
    end
    return oDup:GetMixID()
end

function Srv2Srv.RemoveDup(nSrcServer,nSrcService,nTarSession,nDupMixID)
    local oTarDupObj = goDupMgr:GetDup(nDupMixID)
    if not oTarDupObj then return end

    goDupMgr:RemoveDup(nDupMixID)
end

function Srv2Srv.RemoveUnionDup(nSrcServer,nSrcService,nTarSession,nDupMixID)
    local oDupObj = goDupMgr:GetDup(nDupMixID)
    if not oDupObj then return end

    local tObjList = oDupObj:GetObjList(-1, gtObjType.eRole)
    local nTransDupMixID = 1
    local tPos = {nPosX=0,nPosY=0}
    for _, oObj in ipairs(tObjList) do
        local nRoleID = oObj:GetID()
        Srv2Srv.RoleEnterDup(0,0,0,nRoleID,nTransDupMixID,tPos)
    end
    goDupMgr:RemoveDup(nDupMixID)
end

function Srv2Srv.RoleEnterDup(nSrcServer,nSrcService,nTarSession,nRoleID,nDupMixID,tPos)
    tPos = tPos or {}
    local oRole = goPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then return end
    local oCurrDupObj = oRole:GetCurrDupObj()
    local tCurrDupConf = oCurrDupObj and oCurrDupObj:GetConf()

    local tTarDupConf = ctDupConf[GF.GetDupID(nDupMixID)]
    local nPosX = tPos.nPosX <= 0 and tTarDupConf.tBorn[1][1] or tPos.nPosX
    local nPosY = tPos.nPosY <= 0 and tTarDupConf.tBorn[1][2] or tPos.nPosY

    if (tCurrDupConf and tCurrDupConf.nType == CDupBase.tType.eDup) 
        and (tCurrDupConf.nBattleType ~= tTarDupConf.nBattleType) 
        and not table.InArray(tTarDupConf.nBattleType, tCurrDupConf.tHallBattleType) then
    --策划要求副本中只能通过副本出口离开，此拦截副本中切换场景请求
        --return oRole:Tips("离开副本，请点击右上角退出按钮")
        local tMsg = {sCont="是否确定离开当前副本？", tOption={"取消", "确定"}, nTimeOut=30}
        goClientCall:CallWait("ConfirmRet", function(tData)
            if tData.nSelIdx == 1 then
                return
            elseif tData.nSelIdx == 2 then
                --oRole:EnterLastCity()
                oRole:EnterScene(nDupMixID, nPosX, nPosY, -1, tTarDupConf.nFace)
            end
        end, oRole, tMsg)
    else
        oRole:EnterScene(nDupMixID, nPosX, nPosY, -1, tTarDupConf.nFace)        
    end
end

function Srv2Srv.EnterCheckReq(nSrcServer, nSrcService, nTarSession, nRoleID, nDupMixID, tRoleParam)
    assert(nRoleID and nDupMixID)
    if nDupMixID <= 0 then 
        return false,  "场景ID错误"
    end
    local oDup = goDupMgr:GetDup(nDupMixID)
    if not oDup then 
        return false, "场景不存在"
    end
    return oDup:EnterCheck(nRoleID, tRoleParam)
end

