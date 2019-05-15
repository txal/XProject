--节日活动请求
function CltPBProc.HolidayActAllInfoReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oHolidayActMgr:SendAllActInfo()
end

-------------------------------------------------学富五车-------------------------------------------
function CltPBProc.AnswerAllInfoReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    local oActAnswer = oRole.m_oHolidayActMgr:GetActByHolidayActType(gtHolidayActType.eAnswers)
    if not oActAnswer or not oActAnswer:GetCanJoin() then
        return oRole:Tips("活动不能参加")
    end
    oActAnswer:SendActAllInfo()
end

function CltPBProc.AnswerReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    local oActAnswer = oRole.m_oHolidayActMgr:GetActByHolidayActType(gtHolidayActType.eAnswers)
    if not oActAnswer or not oActAnswer:GetCanJoin() then
        return oRole:Tips("活动不能参加")
    end
    oActAnswer:AnswerReq(tData.nAnswerIndex)
end

------------------------------------------------江湖历练---------------------------------------------
function CltPBProc.ExperienceAcceptReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    local oExperience = oRole.m_oHolidayActMgr:GetActByHolidayActType(gtHolidayActType.eExperience)
    if not oExperience or not oExperience:GetCanJoin() then
        return oRole:Tips("活动不能参加")
    end
    oExperience:ExperienceAcceptReq()
end

function CltPBProc.ExperienceCommitReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    local oExperience = oRole.m_oHolidayActMgr:GetActByHolidayActType(gtHolidayActType.eExperience)
    if not oExperience or not oExperience:GetCanJoin() then
        return oRole:Tips("活动不能参加")
    end
    oExperience:CommitTaskReq(tData.nGatherStatus)
end

------------------------------------------------尊师考验----------------------------------------------
function CltPBProc.TeachTestJoinReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    local oTeachTest = oRole.m_oHolidayActMgr:GetActByHolidayActType(gtHolidayActType.eTeachTest)
    if not oTeachTest or not oTeachTest:GetCanJoin() then
        return oRole:Tips("活动不能参加")
    end
    oTeachTest:JoinTeachTestReq()
end

------------------------------------------------策马奔腾----------------------------------------------
