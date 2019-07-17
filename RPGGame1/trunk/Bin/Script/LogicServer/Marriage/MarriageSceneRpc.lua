------- 客户端服务器 --------
--结婚请求
function Network.CltPBProc.RoleMarryReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    if not goMarriageSceneMgr then
        LuaTrace("当前逻辑服，没有结婚场景管理器")
        return
    end
    goMarriageSceneMgr:WeddingReq(oRole, tData.nTarRoleID)
end

--选择婚礼级别反馈请求
function Network.CltPBProc.MarriageChoosWeddingLevelReactReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    if not goMarriageSceneMgr then
        return
    end
    goMarriageSceneMgr:ChoosWeddingLevelReactReq(oRole, tData.nLevel)
end

--拾取喜糖请求
function Network.CltPBProc.MarriagePickWeddingCandyReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    if not goMarriageSceneMgr then
        return
    end
    goMarriageSceneMgr:PickWeddingCandyReq(oRole, tData.nAOIID, tData.nMonsterID)
end

--花轿租赁请求
function Network.CltPBProc.MarriagePalanquinRentReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    if not goMarriageSceneMgr then
        return
    end
    goMarriageSceneMgr:PalanquinRentReq(oRole)
end

function Network.CltPBProc.MarriagePickItemStateReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    if not goMarriageSceneMgr then
        return
    end
    local oOldMan = goMarriageSceneMgr:GetOldManItemInst()
    local oDup = goMarriageSceneMgr:GetScene()
    if oOldMan and oDup then
        oOldMan:PickItemState(oRole, tData.nAOIID, tData.nMonsterID, oDup)
    end
end



--GM指令刷新月老道具
function Network.RpcSrv2Srv.UpdateOldMan(nSrcServer, nSrcService, nTarSession, nRoleID, nNumber)
    local oOldMan = goMarriageSceneMgr:GetOldManItemInst()
    if oOldMan then
        --TODD先释放之前已经刷新了的
        oOldMan:CleanOldManItem()
        if nNumber == 1 then
             oOldMan:RefreshItem()
        end
    end
end


---------- Svr2Svr ----------




