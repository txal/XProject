--副本/场景基类
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--副本类型
CDupBase.tType = 
{
    eCity = 1,  --城镇
    eDup = 2,   --副本
}

--AOI类型
CDupBase.tAOIType = 
{
    eObserver = 1,  --观察者
    eObserved = 2,  --被观察者
}

--默认AOI宽高
local nDefAOIWidth = 720
local nDefAOIHeight = 1280

function CDupBase:Ctor(nDupID)
    self.m_nDupID = nDupID

    local tDupConf = ctDupConf[self.m_nDupID]
    local bCanCollected = tDupConf.nType == CDupBase.tType.eDup and true or false
    local nDupMixID, oDupObj = goNativeDupMgr:CreateDup(self.m_nDupID, tDupConf.nMapID, bCanCollected)
    self.m_nMixID = nDupMixID
    self.m_oNativeObj = oDupObj

end

function CDupBase:OnRelease()
    self:KickAllRole()
    goNativeDupMgr:RemoveDup(self.m_nMixID)
    self.m_oNativeObj = nil
end

function CDupBase:GetName() return ctDupConf[self.m_nDupID].sName end
function CDupBase:GetDupID() return self.m_nDupID end
function CDupBase:GetMixID() return self.m_nMixID end

--取角色对象
function CDupBase:GetObj(nAOIID) 
    return self.m_oNativeObj:GetObj(nAOIID)
end

--移动角色到指定位置(瞬移)
function CDupBase:MoveObj(nAOIID, nTarX, nTarY)
    return self.m_oNativeObj:MoveObj(nAOIID, nTarX, nTarY)
end

--添加角色的观察者身份
function CDupBase:AddObserver(nAOIID)
    return self.m_oNativeObj:AddObserver(nAOIID)
end

--添加角色的被观察者身份
function CDupBase:AddObserved(nAOIID)
    return self.m_oNativeObj:AddObserved(nAOIID)
end

--移除角色的观察者身份
function CDupBase:RemoveObserver(nAOIID)
    return self.m_oNativeObj:RemoveObserver(nAOIID)
end

--移除角色的被观察者身份
function CDupBase:RemoveObserved(nAOIID)
    return self.m_oNativeObj:AddObserved(nAOIID)
end

--将所有角色移出副本
function CDupBase:KickAllRole()
    self.m_oNativeObj:KickAllRole()
end

--取副本所有的角色对象列表
function CDupBase:GetObjList()
    return self.m_oNativeObj:GetObjList()
end

--取观察该角色的观察者对象列表
--@nObjType: 游戏对象类型,0表示所有
function CDupBase:GetAreaObservers(nAOIID, nObjType)
    return self.m_oNativeObj:GetAreaObservers(nAOIID, nObjType)
end

--取该角色观察区域内的角色对象列表
--@nObjType: 游戏对象类型,0表示所有
function CDupBase:GetAreaObserveds(nAOIID, nObjType)
    return self.m_oNativeObj:GetAreaObserveds(nAOIID, nObjType)
end

--进入副本
--@oNativeObj: C++对象
--@nPosX,nPosY: 坐标
--@nLine: 0公共线; -1自动分线
--@nAOIMode: AOI模式
--@nAOIWidth: AOI宽度
--@nAOIHeight: AOI高度
--返回: AOIID
function CDupBase:Enter(oNativeObj, nPosX, nPosY, nLine)
    assert(type(oNativeObj) == "userdata")
    nLine = nLine or -1 --默认为自动分线

    --先离开旧副本
    local nCurrMixID = oNativeObj:GetDupMixID()
    if nCurrMixID == self:GetMixID() then
        return LuaTrace("角色已经在副本中:", GF.GetDupID(nCurrMixID))
    end
    if nCurrMixID > 0 then
        goDupMgr:LeaveDup(nCurrMixID, oNativeObj:GetAOIID())
    end

    --进入新副本
    local nAOIMode = CDupBase.tAOIType.eObserved
    if oNativeObj:GetSessionID() > 0 then --掉线的玩家没有观察者身份
        nAOIMode = nAOIMode | CDupBase.tAOIType.eObserver
    end

    local nAOIWidth, nAOIHeight = nDefAOIWidth, nDefAOIHeight
    return self.m_oNativeObj:EnterDup(oNativeObj, nPosX, nPosY, nAOIMode, nAOIWidth, nAOIHeight, nLine)
end

--离开副本
function CDupBase:Leave(nAOIID)
    self.m_oNativeObj:LeaveDup(nAOIID)
end
