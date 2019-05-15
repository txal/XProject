--客户端->服务器
function CltPBProc.EnterFBTransitSceneReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    local nPreDupMixID = oRole:GetDupMixID()
    local tDupConf = oRole:GetDupConf()
    local fnConfirmCallback = function (tData)
        if tData.nSelIdx == 2 then 
            --防止玩家选择过程中，队长切换到当前逻辑服其他场景，玩家跟随离开了当前场景
            local nCurDupMixID = oRole:GetDupMixID()
            if nPreDupMixID == nCurDupMixID then 
                if goFBTransitScene then
                    goFBTransitScene:EnterFBTransitScene(oRole)
                else
                    local function CallBack(nMixID, nDupID)
                        assert(ctDupConf[nDupID], "没有此场景配置")
                        local tBornPos = ctDupConf[nDupID].tBorn[1]
                        local nFace = ctDupConf[nDupID].nFace
                        oRole:EnterScene(nMixID, tBornPos[1],  tBornPos[2], -1, nFace)
                    end
                    --通过配置拿到逻辑服id
                    local nDupConfID = 0
                    for nID, tConf in pairs(ctDupConf) do
                        if tConf.nBattleType == gtBattleDupType.eFBTransitScene then
                            nDupConfID = nID
                            break
                        end
                    end
                    local tDupConf = assert(ctDupConf[nDupConfID], "副本不存在:"..nDupConfID)
                    goRemoteCall:CallWait("GetFBTransitSceneMixID", CallBack, oRole:GetStayServer(), tDupConf.nLogic, oRole:GetSession())
                end
            end
        end
    end
    --从副本进入才提示
    if tDupConf.nType == CDupBase.tType.eDup then
        if oRole:GetTeamID() <= 0 or not oRole:IsLeader() then 
            local sCont = "是否确定离开当前副本？"
            local tMsg = {sCont=sCont, tOption={"取消", "确定"}, nTimeOut=15}
            goClientCall:CallWait("ConfirmRet", fnConfirmCallback, oRole, tMsg)
        else --在队伍并且是队长
            --判断是否是镇妖副本，如果是镇妖副本，则提示是否退出副本并且离开队伍
            local bZhenyaoDup = false
            if tDupConf.nBattleType == gtBattleDupType.eZhenYao then 
                bZhenyaoDup = true 
            end
            -- if bZhenyaoDup then
            --     local fnZhenyaoConfirm = function(tData)
            --         if tData.nSelIdx == 2 then 
            --             --rpc退出队伍
            --             --镇妖玩家离开队伍回调事件中，会自动将玩家移除出当前场景
            --             -- local fnQuitTeamCallback = function (bRet)
            --             --     if goFBTransitScene then
            --             --         goFBTransitScene:EnterFBTransitScene(oRole)
            --             --     else
            --             --         local function CallBack(nMixID, nDupID)
            --             --             assert(ctDupConf[nDupID], "没有此场景配置")
            --             --             local tBornPos = ctDupConf[nDupID].tBorn[1]
            --             --             local nFace = ctDupConf[nDupID].nFace
            --             --             oRole:EnterScene(nMixID, tBornPos[1],  tBornPos[2], -1, nFace)
            --             --         end
            --             --         goRemoteCall:CallWait("GetFBTransitSceneMixID", CallBack, oRole:GetStayServer(), 101, oRole:GetSession())
            --             --     end
            --             -- end
            --             -- oRole:QuitTeam(fnQuitTeamCallback)
            --             oRole:QuitTeam()
            --         end
            --     end
            --     local sCont = "是否退出副本，并且离开队伍？"
            --     local tMsg = {sCont=sCont, tOption={"取消", "确定"}, nTimeOut=15}
            --     goClientCall:CallWait("ConfirmRet", fnZhenyaoConfirm, oRole, tMsg)
            -- else
            --     local sCont = "是否确定离开当前副本？"
            --     local tMsg = {sCont=sCont, tOption={"取消", "确定"}, nTimeOut=15}
            --     goClientCall:CallWait("ConfirmRet", fnConfirmCallback, oRole, tMsg)
            -- end

            local sCont = "是否确定离开当前副本？"
            local tMsg = {sCont=sCont, tOption={"取消", "确定"}, nTimeOut=15}
            goClientCall:CallWait("ConfirmRet", fnConfirmCallback, oRole, tMsg)
        end
    else
        local tData = {nSelIdx = 2}
        fnConfirmCallback(tData)
    end
end

--服务器内部
function Srv2Srv.GetFBTransitSceneMixID(nSrcServer, nSrcService, nTarSession)
    if goFBTransitScene then
        local nMixID = goFBTransitScene.m_nDupMixID
        local oDup = goDupMgr:GetDup(nMixID)
        if not oDup then return end
        local nDupID = oDup:GetDupID()
        return nMixID, nDupID
    end
end