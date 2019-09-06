--GLOBAL角色对象(GlobalSrever和WGlobalServer共用)
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CGRole:Ctor()
    self.m_nRoleID = 0
    self.m_sRoleName = ""
    self.m_nRoleConfID = 0
    self.m_nAccountID = 0
    self.m_sAccountName = ""
    self.m_nCreateTime = 0
    self.m_nLevel = 0
    self.m_nVIP = 0
    self.m_nOnlineTime = 0  --上线时间 
    self.m_nOfflineTime = 0 --下线时间 
    self.m_nDupID = 0       --当前所在的副本ID
    self.m_nSceneID = 0     --当前所在的场景ID

    self.m_nServerID = 0        --所属服务器ID(不保存)
    self.m_nSessionID = 0       --当前会话ID(不保存)
    self.m_bReleased = true     --是否逻辑服已释放(不保存)
end

function CGRole:LoadData(tData)
    for sKey, xVal in pairs(tData) do
        self[sKey] = xVal
    end
end

function CGRole:SaveData()
    local tData = {}
    tData.m_nRoleID = self.m_nRoleID
    tData.m_sRoleName = self.m_sRoleName
    tData.m_nRoleConfID = self.m_nRoleConfID
    tData.m_nAccountID = self.m_nAccountID
    tData.m_sAccountName = self.m_sAccountName
    tData.m_nCreateTime = self.m_nCreateTime
    tData.m_nLevel = self.m_nLevel
    tData.m_nVIP = self.m_nVIP
    tData.m_nOnlineTime = self.m_nOnlineTime
    tData.m_nOfflineTime = self.m_nOfflineTime
    tData.m_nDupID = self.m_nDupID
    tData.m_nSceneID = self.m_nSceneID
    return tData
end

--属性更新
function CGRole:UpdateData(tData)
    --关心的属性变化
    local tUpdateMonitor = {
        "m_bReleased" = false,
        "m_nSessionID" = false,
        "m_nDupID"  = false,
        "m_nLevel" = false,
    }
    --旧数据缓存
    local tOldValue = {}

    --更新属性
    for sKey, xVal in pairs(tData) do
        local xOldVal = self[sKey]
        tOldValue[sKey] = xOldVal
        self[sKey] = xVal
        if xOldVal ~= xVal then
            self:MarkDirty(true)
        end
        if tUpdateMonitor[sKey] then
            tUpdateMonitor[sKey] = true
        end
    end

    --事件调用
    for sKey, bVal in pairs(tUpdateMonitor) do
        if bVal then
            if sKey == "m_bReleased" then
                if tVal[1] then
                    self:OnRoleReleased()
                end

            elseif sKey == "m_nSessionID" then
                if tVal[1] > 0 then
                    self:OnRoleOnline()
                else
                    self:OnRoleDisconnect()
                end

            elseif sKey == "m_nDupID" then
                if tVal[1] > 0 then
                    self:OnEnterScene()
                else
                    self:OnLeaveScene(tOldValue.m_nDupID, tOldValue.m_nSceneID)
                end

            elseif sKey == "m_nLevel" then
                self:OnLevelChange()

            end
        end
    end
end

function CGRole:MarkDirty(bDiry)
    GetGModule("GRoleMgr"):MarkDirty(self:GetRoleID(), bDiry)
end

function CGRole:GetRoleID() return self.m_nRoleID end
function CGRole:GetRoleName() return self.m_sRoleName end
function CGRole:GetRoleConfID() return self.m_nRoleConfID end
function CGRole:GetRoleConf() return ctRoleInitConf[self.m_nRoleConfID] end
function CGRole:GetSchool() return self:GetConf().nSchool end
function CGRole:GetGender() return self:GetConf().nGender end
function CGRole:GetHeader() return self:GetConf().sHeader end
function CGRole:GetModel() return self:GetConf().sModel end
function CGRole:IsOnline() return self.m_nSessionID>0 end
function CGRole:GetServerID() return self.m_nServerID end --角色所属服务器ID
function CGRole:GetSessionID() return self.m_nSessionID end
function CGRole:GetGatewayID() return CUtil:GetGateBySession(self.m_nSessionID) end
function CGRole:GetAccountID() return self.m_nAccountID end
function CGRole:GetAccountName() return self.m_sAccountName end
function CGRole:GetCreateTime() return self.m_nCreateTime end
function CGRole:GetVIP() return self.m_nVIP end
function CGRole:GetLevel() return self.m_nLevel end
function CGRole:GetDupID() return self.m_nDupID end
function CGRole:GetSceneID() return self.m_nSceneID end
function CGRole:GetDupConf() return ctDupConf[CUtil:GetDupConfID(self.m_nDupID)] end
function CGRole:IsReleased() return self.m_bReleased end
function CGRole:GetOnlineTime() return self.m_nOnlineTime end
function CGRole:GetOfflineTime() return self.m_nOfflineTime end
function CGRole:GetPower() return self.m_nPower end

--取当前离线时长
function CGRole:GetOfflineKeepTime()
    if self:IsOnline() then
        return 0
    end
    return os.time()-self.m_nOfflineTime
end

--取当前所在逻辑服ID
function CGRole:GetLogicServiceID()
    local tDupConf = self:GetDupConf
    if tDupConf then
        return tDupConf.nLogicServiceID
    end
    return 50
end

--取当前所在的服务器ID和服务ID
function CGRole:GetStayServerAndService()
    local nLogicServiceID = self:GetLogicServiceID()
    return CUtil:GetServerByLogic(nLogicServiceID), nLogicServiceID
end

--进入场景
function CGRole:OnEnterScene()
    goGModuleMgr:OnRoleEnterScene(self)
end

--离开场景
function CGRole:OnLeaveScene(nDupID, nSceneID)
    goGModuleMgr:OnRoleLeaveScene(self, nDupID, nSceneID)
end

--离开副本,一个Dup可能有多个Scene(暂时不调用)
function CGRole:OnLeaveDup(nDupID)
    goGModuleMgr:OnRoleLeaveDup(self, nDupID)
end

--上线
function CGRole:OnRoleOnline()
    goGModuleMgr:OnRoleOnline(self)
end

--离线
function CGRole:OnRoleDisconnect()
    goGModuleMgr:OnRoleDisconnect(self)
end

--释放
function CGRole:OnRoleReleased()
    goGModuleMgr:OnRoleReleased(self)
end

--等级变化
function CGRole:OnLevelChange()
    goGModuleMgr:OnRoleLevelChange(self)
end

--踢玩家下线
function CGRole:KickOffline()
    if not self:IsOnline() then
        return
    end
    local nServerID = self:GetServerID()
    local nSessionID = self:GetSessionID()
    Network.CmdSrv2Srv("KickClientReq", nServer, CUtil:GetGateBySession(nSessionID), nSessionID)
end

--充值成功通知
function CGRole:OnRechargeSucc(tData)
end




--发送消息
function CGRole:SendMsg(sCmd, tMsg, nServerID, nSessionID)
    nServerID = nServerID or self:GetServerID()
    nSessionID = nSessionID or self:GetSessionID()
    if nServerID <= 0 or nSessionID <= 0 then
        return
    end
    assert(nServerID < GetGModule("ServerMgr"):GetWorldServerID(), "服务器ID错了")
    Network.PBSrv2Clt(sCmd, nServerID, nSessionID, tMsg)
end

--飘字通知
function CGRole:Tips(sCont, nServerID, nSessionID)
    self:SendMsg("FloatTipsRet", {sCont=sCont}, nServerID, nSessionID)
end

--道具不足通知
--@tPropList 道具ID列表
function CObjectBase:PropTips(tPropList)
    if not tPropList or #tPropList <= 0 then
        return
    end
    self:SendMsg("PropTipsRet", {tList=tPropList})
end

--添加物品
--@tItemList {{nID=0,nNum=0,bBind=false,tItemExt={}},...}
function CGRole:AddItemList(tItemList, sReason, fnCallback)
    assert(#tItemList>0 and sReason, "参数错误")
    for _, tItem in ipairs(tItemList) do
        assert(tItem.nNum > 0, "物品数量错误")
    end
    local function _fnProxyCallback(bRet)
        if bRet == nil then --超时或失败
            GetGModule("Logger"):EventLog(gtEvent.eLostItem, self, cjson_raw.encode(tItemList), sReason)
            LuaTrace("物品丢失:", self:GetRoleID(), self:GetRoleName(), sReason, tItemList, debug.traceback())
            return self:Tips("发放物品失败")
        end
        if fnCallback then
            fnCallback(bRet)
        end
    end
    local nServerID, nLogicServiceID = self:GetStayServerAndService()
    Network:RMCall("RoleAddItemListReq", _fnProxyCallback, nServerID, nLogicServiceID, self:GetSessionID(), self:GetRoleID(), tItemList, sReason)
end

--扣除物品
--@tItemList {{nID=0,nNum=0,nBind=0},...} @nBind 0非绑; 1绑定; 2先绑定后非绑(全部)
--@return true成功, 否则失败
function CGRole:SubItemList(tItemList, sReason, fnCallback)
    assert(#tItemList>0 and sReason and fnCallback, "参数错误")
    for _, tItem in ipairs(tItemList) do
        assert(tItem.nNum>0, "物品数量错误")
    end
    local nServerID, nLogicServiceID = self:GetStayServerAndService()
    Network:RMCall("RoleSubItemListReq", fnCallback, nServerID, nLogicServiceID, self:GetSessionID(), self:GetRoleID(), tItemList, sReason)
end
