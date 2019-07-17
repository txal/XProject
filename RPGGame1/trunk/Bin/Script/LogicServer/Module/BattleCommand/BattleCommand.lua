--战斗指挥
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CBattleCommand:Ctor(oRole)
    self.m_oRole = oRole
    self.m_tEntmyCommand = {}
    self.m_tFriendCommand = {}
end

function CBattleCommand:LoadData(tData)
    if tData then
        self.m_tEntmyCommand = tData.m_tEntmyCommand
        self.m_tFriendCommand = tData.m_tFriendCommand
    else
        self:InitData()
    end
end

function CBattleCommand:InitData()
    self.m_tEntmyCommand = {
        [101] = "集火",
        [102] = "封印",
        [103] = "守尸",
    }

    self.m_tFriendCommand = {
        [201] = "治疗",
        [202] = "复活",
        [203] = "解封",
    }
    self:MarkDirty(true)
end

function CBattleCommand:SaveData(oRole)
    if not self:IsDirty() then
        return
    end
    self:MarkDirty(false)

    local tData = {}
    tData.m_tEntmyCommand = self.m_tEntmyCommand
    tData.m_tFriendCommand = self.m_tFriendCommand
    return tData
end

function CBattleCommand:GetType(oRole)
    return gtModuleDef.tBattleCommand.nID, gtModuleDef.tBattleCommand.sName
end

function CBattleCommand:GetCommandList()
    local tEnemyList = {}
    for nID, sName in pairs(self.m_tEntmyCommand) do
        table.insert(tEnemyList, {nID=nID, sName=sName})
    end
    local tFriendList = {}
    for nID, sName in pairs(self.m_tFriendCommand) do
        table.insert(tFriendList, {nID=nID, sName=sName})
    end
    return tEnemyList, tFriendList
end

function CBattleCommand:GetEnemyCommand(nID)
    return self.m_tEntmyCommand[nID]
end

function CBattleCommand:GetFriendCommand(nID)
    return self.m_tFriendCommand[nID]
end

function CBattleCommand:SetEnemyCommand(nID, sName)
    if nID <= 103 or nID > 112 then
        return
    end
    if self.m_tEntmyCommand[nID] == sName then
        return true
    end
    self.m_tEntmyCommand[nID] = sName
    self:MarkDirty(true)
    return true
end

function CBattleCommand:SetFriendCommand(nID, sName)
    if nID <= 203 or nID > 212 then
        return
    end
    if self.m_tFriendCommand[nID] == sName then
        return true
    end
    self.m_tFriendCommand[nID] = sName
    self:MarkDirty(true)
    return true
end
