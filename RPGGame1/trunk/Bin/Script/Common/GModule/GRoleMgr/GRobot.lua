--GLOBAL角色机器人对象(GlobalSrever和WGlobalServer共用)
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CGRobot:Ctor()
    CGRole.Ctor(self)
    self.m_bOnline = false
    self.m_nRobotType = gtRobotType.eTeam
end


function CGRobot:IsRobot() return true end
function CGRobot:IsMirror() --是否为玩家镜像
    local nSrcID = self:GetSrcID()
    if nSrcID > 0 and CUtil:IsRobot(nSrcID) then 
        return false 
    end
    return true 
end
function CGRobot:SaveData() end
function CGRobot:IsOnline() return self.m_bOnline end
function CGRobot:SendMsg(sCmd, tMsg, nServer, nSession) end
function CGRobot:Online() 
    self.m_bOnline = true
    self:CommOnline()
end

function CGRobot:Offline()
    self.m_bOnline = false
    CGRole.Offline(self)
end

--是否是组队机器人
--如果是组队机器人，离开队伍，将触发离线销毁
function CGRobot:IsTeamRobot()
    return self.m_nRobotType == gtRobotType.eTeam
end

