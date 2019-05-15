--C++结构
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--通过CPP对象取LUA对象
function GetLuaObjByNativeObj(oNativeObj)
	local nObjID = oNativeObj:GetObjID()
	local nObjType = oNativeObj:GetObjType()
	
	local oLuaObj
	if nObjType == gtObjType.eRole then
		oLuaObj = goPlayerMgr:GetRoleByID(nObjID)
		
	elseif nObjType == gtObjType.eMonster then
		oLuaObj = goMonsterMgr:GetMonster(nObjID)
		
	else
		assert(false, "对象类型错误:" .. nObjType)
	end
	if not oLuaObj then
		return LuaTrace("对象不存在", nObjID, nObjType)
	end
	return oLuaObj
end

--对象进入场景
function OnObjEnterScene(nDupMixID, oNativeObj)
	local oLuaObj = GetLuaObjByNativeObj(oNativeObj)
	if oLuaObj then
		oLuaObj:OnEnterScene(nDupMixID)
	end
end

--对象进入场景完成
function AfterObjEnterScene(nDupMixID, oNativeObj)
	local oLuaObj = GetLuaObjByNativeObj(oNativeObj)
	if oLuaObj then
		oLuaObj:AfterEnterScene(nDupMixID)
	end
end

--对象离开场景
function OnObjLeaveScene(nDupMixID, oNativeObj)
	local oLuaObj = GetLuaObjByNativeObj(oNativeObj)
	if oLuaObj then
		oLuaObj:OnLeaveScene(nDupMixID)
	end
end

--场景对象进入对象
function OnObjEnterObj(nDupMixID, tObserver, tObserved)
	for i = 1, #tObserver do
		local oNativeObj = tObserver[i]
		local nObjType = oNativeObj:GetObjType()
		if nObjType == gtObjType.eRole then
			local nObjID = oNativeObj:GetObjID()
			local oRole = goPlayerMgr:GetRoleByID(nObjID)
			oRole:OnObjEnterObj(tObserved)
			
		else
			assert(false, "对象类型:"..nObjType.."没有观察者对象")
		end
	end
end

--场景对象离开对象
function OnObjLeaveObj(nDupMixID, tObserver, tObserved)
	local tSSList = {}
	for i = 1, #tObserver do
		local oNativeObj = tObserver[i]
		local nObjID = oNativeObj:GetObjID()
		local nObjType = oNativeObj:GetObjType()

		if nObjType == gtObjType.eRole then
			local nSession = oNativeObj:GetSessionID()
			if nSession > 0 then
				local nServer = oNativeObj:GetServerID()
				table.insert(tSSList, nServer)
				table.insert(tSSList, nSession)
			end
		else
			assert(false, "对象类型:"..nObjType.."没有观察者对象")
		end
	end
	local tList = {}
	for i = 1, #tObserved do
		table.insert(tList, tObserved[i]:GetAOIID())
	end
	CmdNet.PBBroadcastExter("ObjLeaveViewRet", tSSList, {tList = tList})
end

--场景被收集
function OnDupCollected(nDupMixID)
	goDupMgr:OnDupCollected(nDupMixID)
end

--对象被收集
function OnObjCollected(nID, nType)
	if nType == gtObjType.eMonster then
		goMonsterMgr:OnMonsterCollected(nID)
	end
end

--对象到达指定坐标
function OnObjReachPos(nID, nType)
	if nType == gtObjType.eMonster then
		local oMonster = goMonsterMgr:GetMonster(nID)
		if oMonster then oMonster:OnReachTargetPos() end
	elseif nType == gtObjType.eRole then 
		local oRole = goPlayerMgr:GetRoleByID(nID)
		if oRole and oRole:IsRobot() then 
			oRole:OnReachTargetPos()
		end
	end
end
