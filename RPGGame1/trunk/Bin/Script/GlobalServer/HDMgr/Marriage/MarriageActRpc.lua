--结婚活动
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert


--请求玩家婚姻数据
function Network.CltPBProc.MarriageActStateReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    local oAct = goHDMgr:GetActivity(gtHDDef.eMarriage)
    if not oAct then 
        return 
    end
    oAct:SyncActState(oRole)
end

------服务器之间-------
function Network.RpcSrv2Srv.MarriageActTriggerReq(nSrcServer, nSrcService, nTarSession, nRoleID)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
    local oAct = goHDMgr:GetActivity(gtHDDef.eMarriage)
    if not oAct then 
        return 
    end
    oAct:Trigger(oRole)
end



