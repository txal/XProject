--服务器内部
function Srv2Srv.StartGuaJiAutoReward(nSrcServer,nSrcService,nTarSession,nRoleID, tData)
    if goGuaJiTimerMgr then
        goGuaJiTimerMgr:StartGuaJiAutoReward(nRoleID, tData.nGuanQia)
    end
end

function Srv2Srv.StopGuaJiAutoReward(nSrcServer,nSrcService,nTarSession,nRoleID, tData)
    if goGuaJiTimerMgr then
        goGuaJiTimerMgr:StopGuaJiAutoReward(nRoleID)
    end
end

function Srv2Srv.ClearGuaJiTimerObj(nSrcServer,nSrcService,nTarSession,nRoleID, tData)
    if goGuaJiTimerMgr then
        goGuaJiTimerMgr:ClearGuaJiTimerObj(nRoleID)
    end
end

function Srv2Srv.IsGuaJi(nSrcServer,nSrcService,nTarSession,nRoleID, tData)
    if goGuaJiTimerMgr then
        return goGuaJiTimerMgr:IsGuaJi(nRoleID)
    end
end

function Srv2Srv.SetIsAutoBattle(nSrcServer,nSrcService,nTarSession,nRoleID, tData)
    if goGuaJiTimerMgr then
        goGuaJiTimerMgr:SetIsAutoBattle(nRoleID, tData)
    end
end

function Srv2Srv.GetIsAutoBattle(nSrcServer,nSrcService,nTarSession,nRoleID, tData)
    if goGuaJiTimerMgr then
        return goGuaJiTimerMgr:GetIsAutoBattle(nRoleID)
    end
end

