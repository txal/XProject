--七脉会武
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert


function CQimaiArena:Ctor(oModul, nActivityID, nSceneID, nOpenTime, nEndTime, nPrepareLastTime)
	print("正在创建<七脉会武>活动实例, 活动ID:"..nActivityID..", 场景ID:"..nSceneID)
	CPVPActivityBase.Ctor(self, oModul, nActivityID, nSceneID, nOpenTime, nEndTime, nPrepareLastTime)
end

function CQimaiArena:GetBattleDupType() return gtBattleDupType.eQimaiArena end 
function CQimaiArena:GetMixDupType(oRole) --玩法类型ID，用于快速组队
	return gtBattleDupType.eQimaiArena
end

function CQimaiArena:CreateRankInst()
	local fnRankCmp = function (tDataL, tDataR)  -- -1排前面, 1排后面
		if tDataL.nScore ~= tDataR.nScore then
			return tDataL.nScore > tDataR.nScore and -1 or 1
		end

		if tDataL.nScore > 0 then 
			if tDataL.nTimeStamp ~= tDataR.nTimeStamp then
				return tDataL.nTimeStamp < tDataR.nTimeStamp and -1 or 1
			end
		else
			--积分为小于等于0的，即输掉，退出比赛的，时间越早，排名越低
			if tDataL.nTimeStamp ~= tDataR.nTimeStamp then
				return tDataL.nTimeStamp > tDataR.nTimeStamp and -1 or 1
			end
		end
		return 0
	end

	local fnSecCmp = function(tDataL, tDataR) 
		if tDataL.nWinCount ~= tDataR.nWinCount then 
			return tDataL.nWinCount > tDataR.nWinCount and -1 or 1
		end

		if tDataL.nLevel ~= tDataR.nLevel then
			return tDataL.nLevel > tDataR.nLevel and -1 or 1
		end

		if tDataL.nRoleID ~= tDataR.nRoleID then 
			return tDataL.nRoleID < tDataR.nRoleID and -1 or 1
		end
	end
	local oRank = CRBRank:new(fnRankCmp, fnSecCmp, true, 5) 
	return oRank
end

function CQimaiArena:CheckEnd() 
	if not self:IsStart() then --只有当前活动处于已开始状态，才有检查结束的必要性
		return false
	end
	local bEnd = self:CheckTimeEnd()
	if bEnd then
		return true
	end

	local nEndNum = 1  --剩余队伍数量小于等于此值时，活动结束
	local nTeamNum = 0
	local tTeamMap = {}
	for k, oRoleData in pairs(self.m_tRoleMap) do
		if oRoleData:IsActive() then
			local oRole = goPlayerMgr:GetRoleByID(oRoleData:GetRoleID())
			if oRole then 
				if oRole:GetTeamID() == 0 or oRole:IsTeamLeave() then 
					nTeamNum = nTeamNum + 1 --单人或者暂离状态，当做一个独立队伍计算
					if nTeamNum > nEndNum then --没必要继续计算了
						return false 
					end
				else
					local nTeamID = oRole:GetTeamID()
					if not tTeamMap[nTeamID] then 
						tTeamMap[nTeamID] = true
						nTeamNum = nTeamNum + 1 
						if nTeamNum > nEndNum then 
							return false
						end
					end
				end
			end
		end
	end
	if nTeamNum > nEndNum then 
		return false
	end
	return true 
end


