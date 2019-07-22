--神兽乐园挑战请求
-- function Network.CltPBProc.ShenShouLeYuanChalReq(nCmd, nServer, nService, nSession, tData)
--     local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
--     if not oRole then return end

--     local oBattleDup = goBattleDupMgr:GetBattleDup(oRole:GetBattleDupID())
--     if oBattleDup and oBattleDup.Opera then
--         oBattleDup:Opera(oRole, tData.nChalType)
--     end
-- end