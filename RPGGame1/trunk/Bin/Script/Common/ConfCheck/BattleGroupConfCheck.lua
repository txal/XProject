local function _BattleGroupConfCheck()
	for nGroupID, tConf in pairs(ctBattleGroupConf)	do
		for k = 1, 10 do		
			local tSubMonsterList = tConf["tPos"..k]
			for _, tSubMonster in ipairs(tSubMonsterList) do
				if tSubMonster[1] > 0 then
					assert(ctSubMonsterConf[tSubMonster[1]], "战斗组:"..nGroupID.." 位置:tPos"..k.." 子怪物不存在:"..tSubMonster[1])
				end
			end
		end
	end
end
_BattleGroupConfCheck()