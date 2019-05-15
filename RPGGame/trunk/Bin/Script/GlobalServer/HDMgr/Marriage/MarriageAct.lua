--开服结婚活动
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert


function CMarriageAct:Ctor(nActID)
    CHDBase.Ctor(self, nActID)
    self.m_tRoleRecordMap = {} 
end

function CMarriageAct:LoadData()
    --这里，servermgr已经初始化好
    local oSSDB = goDBMgr:GetSSDB(gnServerID, "global", GF.GetServiceID())
    local sData = oSSDB:HGet(gtDBDef.sHuoDongDB, self:GetID())
    
    if sData ~= "" then
        local tData = cjson.decode(sData)
        CHDBase.LoadData(self, tData)
        self.m_tRoleRecordMap = tData.m_tRoleRecordMap
    end
    -- 暂时屏蔽掉开服自动开启，策划新需求要求取消这个活动
    -- if not self:IsOpen() then --如果当前没开启
    --     local nBeginTime = goServerMgr:GetOpenZeroTime(gnServerID)
    --     local nDays = ctYuanfen[1].nDay
    --     if nDays and nDays >= 1 then 
    --         local nEndTime = nBeginTime + (nDays*24*3600) - 1
    --         if nBeginTime > 0 and nEndTime > os.time() then 
    --             self:OpenAct(nBeginTime, nEndTime, 0)
    --             self:MarkDirty(true)
    --         end
    --     end
    -- end
end

function CMarriageAct:SaveData()
    if not self:IsDirty() then
		return
	end
	local tData = CHDBase.SaveData(self)
	tData.m_tRoleRecordMap = self.m_tRoleRecordMap

	local oSSDB = goDBMgr:GetSSDB(gnServerID, "global", GF.GetServiceID())
	oSSDB:HSet(gtDBDef.sHuoDongDB, self:GetID(), cjson.encode(tData))
	self:MarkDirty(false)
end

function CMarriageAct:OnStateInit()
    CHDBase.OnStateInit(self)
    self.m_tRoleRecordMap = {}
    self:MarkDirty(true)
end

--进入活动状态
function CMarriageAct:OnStateStart()
    CHDBase.OnStateStart(self)
    self.m_tRoleRecordMap = {}
    self:MarkDirty(true)
    self:SyncActState()
end

--进入领奖状态
function CMarriageAct:OnStateAward()
    CHDBase.OnStateAward(self)
    -- self:SyncActState()
end

--进入关闭状态
function CMarriageAct:OnStateClose()
    CHDBase.OnStateClose(self)
    self:SyncActState()
end

function CMarriageAct:Online(oRole)
    self:SyncActState(oRole)
end

function CMarriageAct:IsRecorded(nRoleID)
    if self.m_tRoleRecordMap[nRoleID] then 
        return true 
    else
        return false
    end
end

function CMarriageAct:SyncActState(oRole)
    local tMsg = {}   --活动状态
    local nCurTime = os.time()
    tMsg.nActID = self:GetID()
    tMsg.bOpen = self:IsOpen()
    if tMsg.bOpen then 
        tMsg.nBeginTime = self.m_nBegTime
        tMsg.nEndTime = self.m_nEndTime
        tMsg.nCurTime = nCurTime
    end
    if oRole then 
        tMsg.bRecord = self:IsRecorded(oRole:GetID())
        oRole:SendMsg("MarriageActStateRet", tMsg)
    else 
        local tSessionMap = goGPlayerMgr:GetRoleSSMap()
        for nSession, oTmpRole in pairs(tSessionMap) do
            if tMsg.bOpen then 
                tMsg.bRecord = self:IsRecorded(oTmpRole:GetID())
            end
			oTmpRole:SendMsg("MarriageActStateRet", tMsg)
		end
    end
end

function CMarriageAct:Trigger(oRole)
    if not self:IsOpen() then 
        return 
    end
    if not oRole or oRole:IsRobot() then 
        return 
    end
    local nRoleID = oRole:GetID()
    if self.m_tRoleRecordMap[nRoleID] then 
        return 
    end
    self.m_tRoleRecordMap[nRoleID] = os.time()

    local tRewardConf = ctYuanfen[1].tAward
    local tRewardList = {}
    for k, tConf in ipairs(tRewardConf) do 
        if tConf[1] > 0 and tConf[2] > 0 and tConf[3] > 0 then 
            table.insert(tRewardList, tConf)
        end
    end
    if #tRewardList > 0 then 
        GF.SendMail(oRole:GetServer(), "结婚活动", "结婚活动奖励", tRewardList, oRole:GetID())
        self:SyncActState(oRole)
        self:MarkDirty(true)
    end
end


