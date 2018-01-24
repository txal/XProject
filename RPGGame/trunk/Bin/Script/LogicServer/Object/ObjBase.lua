function CObjBase:Ctor(nObjType, sObjID, sObjName, nConfID, tBattle, oCppObj)
	self.m_nObjType = nObjType
	self.m_sObjID = sObjID
	self.m_sObjName = sObjName
	self.m_nConfID = nConfID

	self.m_tBattle = tBatttle or {nType=0,nCamp=0,tData={}} --tData={nRoomID=0,[nRoomStage=0]}
	self.m_oCppObj = oCppObj
	self.m_nSceneIndex = 0
end

function CObjBase:OnRelease()
	self.m_oCppObj = nil
	self.m_nSceneIndex = 0
end

function CObjBase:OnEnterScene(nSceneIndex)
	self.m_nSceneIndex = nSceneIndex
end

function CObjBase:OnLeaveScene(nSceneIndex)
	assert(nSceneIndex == self.m_nSceneIndex, "场景ID错误")
	self.m_nSceneIndex = 0
	self.m_tBattle = {nType=0,nCamp=0,tData={}}
end

function CObjBase:GetObjType() return self.m_nObjType end
function CObjBase:GetObjID() return self.m_sObjID end
function CObjBase:GetConfID() return self.m_nConfID end
function CObjBase:GetName() return self.m_sObjName end
function CObjBase:GetCppObj() return self.m_oCppObj end

function CObjBase:IsBattling()
	return self.m_tBattle.nType > 0
end

--取位置
function CObjBase:GetPos()
	return self.m_oCppObj:GetPos()
end

--取AOIID
function CObjBase:GetAOIID()
	return self.m_oCppObj:GetAOIID()
end

--取场景对象
function CObjBase:GetScene()
	return goLuaSceneMgr:GetSceneByIndex(self.m_nSceneIndex)
end

--取战斗信息
function CObjBase:GetBattle()
	return self.m_tBattle
end

--设置战斗类型
function CObjBase:SetBattle(tBattle)
    local tCopy = {nType=0,nCamp=0,tData={}}
    if tBattle then
        tCopy.nType = tBattle.nType or 0
        tCopy.nCamp = tBattle.nCamp or 0
        for k, v in pairs(tBattle.tData or {}) do
            tCopy.tData[k] = v
        end
    end

    if tCopy.nType > 0 and self.m_tBattle.nType > 0 then
        assert(false, "当前正在战斗中:"..table.ToString(self.m_tBattle, true))
    end
    self.m_tBattle = tCopy
    self.m_oCppObj:SetCamp(self.m_tBattle.nCamp)
end
