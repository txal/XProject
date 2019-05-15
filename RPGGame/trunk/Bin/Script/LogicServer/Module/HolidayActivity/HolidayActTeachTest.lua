--尊师考验
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CHolidayActTeachTest:Ctor(oRole, nActID, nActType)
    self.m_oRole = oRole
    CHolidayActivityBase.Ctor(self, nActID, nActType)
end

function CHolidayActTeachTest:GetHolidayActData()
    return self.m_oRole.m_oHolidayActMgr.m_tActData
end

function CHolidayActTeachTest:CheckCanJoin()
    --能参加条件已开启，等级足够，次数未用完
    local nEndTimestamp = self:GetEndTimestamp()
    --print(">>>>>>>>>>>>>>>>>>>>>>>>>>尊师考验时间:"..os.date("%c",nEndTimestamp))
    local bIsActOpen = self:GetActIsBegin()
    --print(">>>>>>>>>>>>>>>>>>>>>>>>尊师考验是否开启: "..tostring(bIsActOpen))
    local bLevelEnouht = self.m_oRole:GetLevel() >= ctHolidayActivityConf[self.m_nActID].nLevelLimit
    local tData = self:GetHolidayActData()
    local nActID = self:GetActID()
    assert(ctHolidayActivityConf[nActID], "配置没有此活动")
    local nMaxJoin = ctHolidayActivityConf[nActID].nCanJoinTimes
    local bOldStatus = self.m_bCanJoin
    if bIsActOpen and bLevelEnouht and tData.nTeachTestCompTimes < nMaxJoin then
        local bNewStatus = true
        if bOldStatus ~= bNewStatus then
            self.m_bCanJoin = bNewStatus
            self:OnActStart()
        end
    else
        local bNewStatus = false
        if bOldStatus ~= bNewStatus then
            self.m_bCanJoin = bNewStatus
        end
    end
end

function CHolidayActTeachTest:OnActStart()
    local tData = self:GetHolidayActData()
    if tData.nTeachTestCompTimes > 0 and os.time() >= tData.nTeachTestCompTimes then
        self:ClearData()
    end
end

function CHolidayActTeachTest:SetKillMonsterTimes(nIndex)
    local tData = self:GetHolidayActData()
    local nOldTimes = tData.tTeachTestKillMonMap[nIndex] or 0
    tData.tTeachTestKillMonMap[nIndex] = nOldTimes + 1
    self.m_oRole.m_oHolidayActMgr:MarkDirty(true)
end

function CHolidayActTeachTest:SetTeachTestCompTimes()
    local tData = self:GetHolidayActData()
    local nOldTimes = tData.nTeachTestCompTimes
    tData.nTeachTestCompTimes = nOldTimes + 1
    self.m_oRole.m_oHolidayActMgr:MarkDirty(true)
end

function CHolidayActTeachTest:GetKillMonsterTimes(nIndex)
    local tData = self:GetHolidayActData()
    local nTimes = tData.tTeachTestKillMonMap[nIndex] or 0
    return nTimes
end

function CHolidayActTeachTest:GetTotalMonsterNum()
    local nCount = 0
    for _, tConf in pairs(ctTeachTestConf) do
        nCount = nCount + 1
    end
    return nCount
end

--计算已经击杀过几个怪物(奖励需要根据击杀的是第几只作参数计算)
function CHolidayActTeachTest:GetAlreadyKillMonCount()
    local nCount = 0
    local tData = self:GetHolidayActData()
    for nIndex, nValue in pairs(tData.tTeachTestKillMonMap) do
        if nValue > 0 then
            nCount = nCount + 1
        end
    end
    return nCount
end

function CHolidayActTeachTest:Online()
    self:CheckCanJoin()
end

function CHolidayActTeachTest:OnMinTimer()
    CHolidayActivityBase.OnMinTimer(self)
    self:CheckCanJoin()
end

function CHolidayActTeachTest:ClearData()
    local tData = self:GetHolidayActData()
    tData.nTeachTestCompTimes = 0
end

function CHolidayActTeachTest:JoinTeachTestReq()
    print(">>>>>>>>>>>>>>>>>>>>>>>>>>参加尊师考验活动")
    --检查人数、等级
    self.m_oRole:GetTeam(function(nTeamID, tTeam)
        if nTeamID == 0 then
            return self.m_oRole:Tips("尊师考验需要组队才能前往")
        else
            --自己是队长
            local tConf = ctBattleDupConf[gtBattleDupType.eTeachTest]
            if tTeam[1].nRoleID == self.m_oRole:GetID() then 
                -- --检查人数
                -- if #tTeam < tConf.nTeamMembs then
                --     return self.m_oRole:Tips("组队人数不足")
                -- end
                
                --检查人员等级
                local bAllCanJoin = true
                local nLevelLimit = tConf.nLevelLimit
                local sStr = ""
                for _, tRole in ipairs(tTeam) do 
                    local oRole = goPlayerMgr:GetRoleByID(tRole.nRoleID)
                    if oRole then
                        if oRole.m_nLevel < nLevelLimit then
                            sStr = sStr .. oRole.m_sName .. ", "
                            bAllCanJoin = false
                        end
                    end
                end
                if not bAllCanJoin then
                    return oRole:Tips(sStr.."等级不足"..nLevelLimit.."级,不能进入副本")				
                end

                --可能会切换服务进程 
                goBattleDupMgr:CreateBattleDup(gtBattleDupType.eTeachTest, function(nDupMixID)
                    local tConf = assert(ctDupConf[GF.GetDupID(nDupMixID)])
                    self.m_oRole:EnterScene(nDupMixID, tConf.tBorn[1][1], tConf.tBorn[1][2], -1, tConf.nFace)
                end)

            --自己不是队长
            else
                self.m_oRole:Tips("你已经有队伍了，只有队长才能带队前往哦")
            end
        end
    end)
end

function CHolidayActTeachTest:GetActStatusInfo()
    local tData = self:GetHolidayActData()
    local tConf = self:GetConf()
    local tActInfo = {}
    tActInfo.nActivityID = self.m_nActID
    tActInfo.nTodayCompTimes = tData.nTeachTestCompTimes
    tActInfo.nTotalTimes = tConf.nCanJoinTimes
    tActInfo.bCanJoin = self:GetCanJoin()
    tActInfo.bIsComp = tData.nTeachTestCompTimes >= tConf.nCanJoinTimes
    tActInfo.bIsEnd = os.time() >= self:GetEndTimestamp()
    return tActInfo
end
