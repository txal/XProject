--GLOBAL角色对象
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CGRole:Ctor()
    self.m_nID = 0
    self.m_sName = ""
    self.m_nAccountID = 0
    self.m_sAccountName = ""
    self.m_nCreateTime = 0
    self.m_nServer = 0

    self.m_nLevel = 0
    self.m_nVIP = 0

    --不保存
    self.m_nDupID = 0   --当前所在的副本ID
    self.m_nSession = 0 --当前会话ID
end

--第1次创建初始化
function CGRole:Init(tData)
    for sKey, xVal in pairs(tData) do
        self[sKey] = xVal
    end
end

function CGRole:LoadData(tData)
    for sKey, xVal in pairs(tData) do
        self[sKey] = xVal
    end
end

function CGRole:SaveData()
    local tData = {}
    tData.m_nID = self.m_nID
    tData.m_sName = self.m_sName
    tData.m_nAccountID = self.m_nAccountID
    tData.m_sAccountName = self.m_sAccountName
    tData.m_nCreateTime = self.m_nCreateTime
    tData.m_nServer = self.m_nServer
    
    tData.m_nLevel = self.m_nLevel
    tData.m_nVIP = self.m_nVIP
    return tData
end

function CGRole:UpdateReq(tData)
    for sKey, xVal in pairs(tData) do
        self[sKey] = xVal
    end
end

function CGRole:GetID() return self.m_nID end
function CGRole:GetName() return self.m_sName end
function CGRole:IsOnline() return self.m_nSession > 0 end
function CGRole:GetServer() return self.m_nServer end
function CGRole:GetSession() return self.m_nSession end
function CGRole:GetAccountID() return self.m_nAccountID end
function CGRole:GetAccountName() return self.m_sAccountName end
function CGRole:GetCreateTime() return self.m_nCreateTime end
function CGRole:GetLevel() return self.m_nLevel end
function CGRole:GetVIP() return self.m_nVIP end

function CGRole:GetLogic()
    local tConf = ctDupConf[self.m_nDupID]
    if tConf then
        return tConf.nLogic
    end
    return 0
end

function CGRole:Online(nSession)
    self.m_nSession = nSession
end

function CGRole:Offline()
    self.m_nSession = 0
end

function CGRole:Tips(sCont, nServer, nSession)
    nServer = nServer or self.m_nServer
    nSession = nSession or self.m_nSession
    CmdNet.PBSrv2Clt(nServer, nSession, "TipsMsgRet", {sCont=sCont})
end

function CGRole:ItemCount(nType, nID, fnCallBack)
    if fnCallBack then
        goRemoteCall:CallWait("RoleItemCountReq", fnCallBack, self:GetServer(), self:GetLogic(), self:GetSession(), self:GetAccountID(), nType, nID)
    else
        goRemoteCall:Call("RoleItemCountReq", self:GetServer(), self:GetLogic(), self:GetSession(), self:GetAccountID(), nType, nID)
    end
end

function CGRole:AddItem(tItemList, sReason, fnCallBack)
    assert(#tItemList>0 and sReason, "参数错误")
    if fnCallBack then
        goRemoteCall:CallWait("RoleAddItemReq", fnCallBack, self:GetServer(), self:GetLogic(), self:GetSession(), self:GetAccountID(), tItemList, sReason)
    else
        goRemoteCall:Call("RoleAddItemReq", self:GetServer(), self:GetLogic(), self:GetSession(), self:GetAccountID(), tItemList, sReason)
    end
end
