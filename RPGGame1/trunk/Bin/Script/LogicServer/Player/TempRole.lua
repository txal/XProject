--临时角色对象
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert


--临时角色创建后，必须手动调用Release()释放掉
function CTempRole:Ctor(nServer, nRoleID)
    assert(nServer and nRoleID)
    CRole.Ctor(self, nServer, nRoleID)
    --创建角色时，会自动创建并挂载一个Cpp对象，这个对象，临时角色基本不需要使用，创建好之后，直接销毁
    self.m_oNativeObj = nil
    goNativePlayerMgr:RemoveRole(nRoleID)
    self:CleanRoleTimer() --创建时，会自动注册定时器，执行定时保存之类功能
end

function CTempRole:Release()
    self:OnTempObjRelease()
end

function CTempRole:IsTempRole() return true end
--防止影响玩家的正常数据
function CTempRole:SaveData() end
function CTempRole:SyncRoleLogic(bRelease) end
function CTempRole:UpdateRoleSummary() end
function CTempRole:SendMsg(sCmd, tMsg, nServer, nSession) end
function CTempRole:AddItem(nItemType, nItemID, nItemNum, sReason, bRawExp, bBind, tPropExt) end




