local _tRobotFameList = {}
local function _BuildRobotConf()
	local nCount = 0
	for k, tConf in pairs(ctRobotConf) do
		nCount = nCount + 1
		table.insert(_tRobotFameList, tConf.nFame)
		local bCurrGun = false
		for m = 1, 4 do
			local tGunConf = tConf["tGun"..m]
			if tConf.nCurrGun == tGunConf[1][1] then
				bCurrGun = true
			end
			assert(ctArmConf[tGunConf[1][1]], "RobotConf.xml 机器人"..k.."枪支"..m.."不存在")
			for n = 2, #tGunConf do
				assert(ctGunFeatureConf[tGunConf[n][1]], "RobotConf.xml 机器人"..k.."枪支"..m.."特性不存在")
			end
		end
		assert(bCurrGun, "RobotConf.xml 机器人"..k.."当前枪支错误")
		for k1, tBombConf in ipairs(tConf.tBombList) do
			if tBombConf[1] > 0 then
				assert(ctArmConf[tBombConf[1]], "RobotConf.xml 机器人"..k.."炸弹"..k1.."不存在")
			end
		end
	end
	assert(nCount == #ctRobotConf, "RobotConf.xml 编号必须连续")	

	for _, tConf in pairs(ctNewbieConf) do
		for _, tRobot in ipairs(tConf.tSelfRobot) do
			assert(ctRobotConf[tRobot[1]], "NewbieConf.xml机器人不存在:"..tRobot[1])
		end
		for _, tRobot in ipairs(tConf.tEnemyRobot) do
			assert(ctRobotConf[tRobot[1]], "NewbieConf.xml机器人不存在:"..tRobot[1])
		end
	end
end
_BuildRobotConf()

function FindRobotByFame(nFame)
	local nRobotID = gtAlg.BinaryFind(_tRobotFameList, nFame)
	assert(ctRobotConf[nRobotID], "找不到机器人,声望:"..nFame)
	return nRobotID
end