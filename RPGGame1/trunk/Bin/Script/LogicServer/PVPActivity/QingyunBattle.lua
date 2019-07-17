--青云之战
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert


function CQingyunBattle:Ctor(oModul, nActivityID, nSceneID, nOpenTime, nEndTime, nPrepareLastTime)
	print("正在创建<青云之战>活动实例, 活动ID:"..nActivityID..", 场景ID:"..nSceneID)
	CPVPActivityBase.Ctor(self, oModul, nActivityID, nSceneID, nOpenTime, nEndTime, nPrepareLastTime)
end

function CQingyunBattle:GetBattleDupType() return gtBattleDupType.eQingyunBattle end 
function CQingyunBattle:GetMixDupType(oRole) --玩法类型ID，用于快速组队
	return gtBattleDupType.eQingyunBattle
end











