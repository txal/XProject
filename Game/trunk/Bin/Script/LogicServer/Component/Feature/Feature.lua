local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

local tFTFuncMap = {}
local tFTAttrType = gtFeatureAttrType

--枪支本身特性属性
function CastGunFeature(tGun, tFeature)
	local tFTAttr = CArmItem:CalcFeatureAttr(tFeature)
	for nType, tVal in pairs(tFTAttr) do
		if tFTFuncMap[nType] then
			tFTFuncMap[nType](tGun, tVal)
		else
			LuaTrace("特性类型:"..nType.."未定义")
		end
	end
end

--动态属性相关特性
function CastDyncFeature(tFeature, oActor, tOldFeature)
	--移除旧属性
	if tOldFeature then
		local tOldFTAttr = CArmItem:CalcFeatureAttr(tOldFeature)
		for nType, tVal in pairs(tOldFTAttr) do
			if tFTFuncMap[nType] then
				tFTFuncMap[nType](nil, tVal, oActor, true)
			end
		end
	end

	--添加新属性
	local tFTAttr = CArmItem:CalcFeatureAttr(tFeature)
	for nType, tVal in pairs(tFTAttr) do
		if tFTFuncMap[nType] then
			tFTFuncMap[nType](nil, tVal, oActor)
		else
			LuaTrace("特性类型:"..nType.."未定义")
		end
	end
end

--弹夹上限
tFTFuncMap[tFTAttrType.eClip] = function(tGun, tVal)
	if not tGun then
		return
	end
	print("特性弹夹上限")
	tGun.uClipCap = math.floor(tGun.uClipCap * (1 + tVal[1] * 0.0001))
end

--备用弹夹上限
tFTFuncMap[tFTAttrType.eBackupClip] = function(tGun, tVal)
	if not tGun then
		return
	end
	print("特性备用弹夹上限")
	tGun.uBulletBackup = math.floor(tGun.uBulletBackup * (1 + tVal[1] * 0.0001))
end

--装填速度
tFTFuncMap[tFTAttrType.eReloadSpeed] = function(tGun, tVal)
	if not tGun then
		return
	end
	print("特性装填速度")
	tGun.uReloadTime = math.floor(tGun.uReloadTime * (1 - tVal[1] * 0.0001))
end

--稳定性
tFTFuncMap[tFTAttrType.eStability] = function(tGun, tVal)
end

--忽略目标防御
tFTFuncMap[tFTAttrType.eIgnoreDef] = function(tGun, tVal)
end

--暴击概率
tFTFuncMap[tFTAttrType.eCritRate] = function(tGun, tVal, oActor, bReset)
	if not oActor then
		return
	end
	local tRuntimeBattleAttr = oActor:GetRuntimeBattleAttr()
	local nAttrID = tVal[1]
	if nAttrID < gtAttrDef.eAtk or nAttrID > gtAttrDef.eNorDmg then
		return
	end
	local nNewAttr = tRuntimeBattleAttr[nAttrID]
	if bReset then
		print(oActor:GetName(), "特性暴击概率恢复")
		nNewAttr = math.floor(nNewAttr * (1 - tVal[2] * 0.0001))
	else
		print(oActor:GetName(), "特性暴击概率增加")
		nNewAttr = math.floor(nNewAttr * (1 + tVal[2] * 0.0001))
	end
	oActor:GetCppObj():UpdateFightParam(nAttrID, nNewAttr)

	local nAOIID = oActor:GetAOIID()
    local oScene = oActor:GetScene()
	local tSessionList = oScene:GetSessionList(nAOIID, true)
	local tAttrList = {{nID=nAttrID, nVal=nNewAttr}}
	CmdNet.PBBroadcastExter(tSessionList, "ActorBattleAttrSync", {nAOIID=nAOIID, tAttr=tAttrList})
end

--暴击伤害
tFTFuncMap[tFTAttrType.eCritHurt] = function(tGun, tVal, oActor, bReset)
	if not oActor then
		return
	end
	local tRuntimeBattleAttr = oActor:GetRuntimeBattleAttr()
	local nAttrID = tVal[1]
	if nAttrID < gtAttrDef.eAtk or nAttrID > gtAttrDef.eNorDmg then
		return
	end
	local nNewAttr = tRuntimeBattleAttr[nAttrID]
	if bReset then
		print(oActor:GetName(),"特性暴击伤害恢复")
		nNewAttr = math.floor(nNewAttr * (1 - tVal[2] * 0.0001))
	else
		print(oActor:GetName(),"特性暴击伤害增加")
		nNewAttr = math.floor(nNewAttr * (1 + tVal[2] * 0.0001))
	end
	oActor:GetCppObj():UpdateFightParam(nAttrID, nNewAttr)

	local nAOIID = oActor:GetAOIID()
    local oScene = oActor:GetScene()
	local tSessionList = oScene:GetSessionList(nAOIID, true)
	local tAttrList = {{nID=nAttrID, nVal=nNewAttr}}
	CmdNet.PBBroadcastExter(tSessionList, "ActorBattleAttrSync", {nAOIID=nAOIID, tAttr=tAttrList})
end

--暴击抗性
tFTFuncMap[tFTAttrType.eCritCounter] = function(tGun, tVal, oActor, bReset)
	if not oActor then
		return
	end
	local tRuntimeBattleAttr = oActor:GetRuntimeBattleAttr()
	local nAttrID = tVal[1]
	if nAttrID < gtAttrDef.eAtk or nAttrID > gtAttrDef.eNorDmg then
		return
	end
	local nNewAttr = tRuntimeBattleAttr[nAttrID]
	if bReset then
		print(oActor:GetName(),"特性暴击抗性恢复")
		nNewAttr = math.floor(nNewAttr * (1 - tVal[2] * 0.0001))
	else
		print(oActor:GetName(),"特性暴击抗性增加")
		nNewAttr = math.floor(nNewAttr * (1 + tVal[2] * 0.0001))
	end
	oActor:GetCppObj():UpdateFightParam(nAttrID, nNewAttr)

	local nAOIID = oActor:GetAOIID()
    local oScene = oActor:GetScene()
	local tSessionList = oScene:GetSessionList(nAOIID, true)
	local tAttrList = {{nID=nAttrID, nVal=nNewAttr}}
	CmdNet.PBBroadcastExter(tSessionList, "ActorBattleAttrSync", {nAOIID=nAOIID, tAttr=tAttrList})
end

--两次伤害
tFTFuncMap[tFTAttrType.eDoubleHurt] = function(tGun, tVal)
end

--反震伤害
tFTFuncMap[tFTAttrType.eHurtCounter] = function(tGun, tVal)
end

--枪支伤害免疫
tFTFuncMap[tFTAttrType.eGunHurtImmune] = function(tGun, tVal)
end

--移动速度
tFTFuncMap[tFTAttrType.eMoveSpeed] = function(tGun, tVal, oActor, bReset)
	if not oActor then
		return
	end
	local oCppObj = oActor:GetCppObj()
	local nCurrSpeed = oCppObj:GetFightParam(gtAttrDef.eSpeed)
	if bReset then
		print(oActor:GetName(),"特性移动速度恢复")
		nCurrSpeed = math.floor(nCurrSpeed * (1 - tVal[1] * 0.0001))
	else
		print(oActor:GetName(),"特性移动速度增加")
		nCurrSpeed = math.floor(nCurrSpeed * (1 + tVal[1] * 0.0001))
	end
	oCppObj:UpdateFightParam(gtAttrDef.eSpeed, nCurrSpeed)
	if oActor:GetObjType() == gtObjType.ePlayer then
		local tAttrList = {{nID=gtAttrDef.eSpeed, nVal=nCurrSpeed}}
		CmdNet.PBSrv2Clt(oActor:GetSession(), "ActorBattleAttrSync", {nAOIID=oActor:GetAOIID(), tAttr=tAttrList})
	end
end

--射击速度
tFTFuncMap[tFTAttrType.eShotSpeed] = function(tGun, tVal)
	if not tGun then
		return
	end
	tGun.uTimePerShot = math.floor(tGun.uTimePerShot * (1 - tVal[1] * 0.0001))
end

--眩晕状态持续
tFTFuncMap[tFTAttrType.eVertigoState] = function(tGun, tVal)
end

--减速状态持续
tFTFuncMap[tFTAttrType.eSpeedDownState] = function(tGun, tVal)
end

--回复子弹
tFTFuncMap[tFTAttrType.eBulletReturn] = function(tGun, tVal)
end

--眩晕免疫
tFTFuncMap[tFTAttrType.eVertigoImmune] = function(tGun, tVal)
end

--减速免疫
tFTFuncMap[tFTAttrType.eSpeedDownImmune] = function(tGun, tVal)
end

--吸血
tFTFuncMap[tFTAttrType.eVampire] = function(tGun, tVal)
end

--加速状态持续
tFTFuncMap[tFTAttrType.eSpeedUpState] = function(tGun, tVal)
end

--狂野状态持续	
tFTFuncMap[tFTAttrType.eCrazyState] = function(tGun, tVal)
end

--治疗加成
tFTFuncMap[tFTAttrType.eCure] = function(tGun, tVal)
end
