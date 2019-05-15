--首席争霸
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CSchoolArena:Ctor(oModul, nActivityID, nSceneID, nSchoolID, nOpenTime, nEndTime, nPrepareLastTime)
	print("正在创建<首席争霸>活动实例, 活动ID:"..nActivityID..", 场景ID:"..nSceneID..", 门派ID:"..nSchoolID)
	CPVPActivityBase.Ctor(self, oModul, nActivityID, nSceneID, nOpenTime, nEndTime, nPrepareLastTime)
	self.m_nSchoolID = nSchoolID
end

function CSchoolArena:GetSchoolID() return self.m_nSchoolID end
function CSchoolArena:GetBattleDupType() return gtBattleDupType.eSchoolArena end 
function CSchoolArena:GetMixDupType(oRole) --玩法类型ID，用于快速组队
	local nSchoolID = self:GetSchoolID()
	return (nSchoolID <<  32) | gtBattleDupType.eSchoolArena
end
function CSchoolArena:GetDupTypeName(oRole) --组队区分
	local tConf = self:GetConf()
	return (tConf.sActivityName.."["..gtSchoolName[self:GetSchoolID()].."]")
end


