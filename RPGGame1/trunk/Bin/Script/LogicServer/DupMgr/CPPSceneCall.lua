--CPP 场景相关回调

--游戏对象进入场景
function OnObjEnterScene(oSceneNativeObj, oGameNativeObj)
	local oSceneLuaObj = oSceneNativeObj:GetLuaObj()
	assert(oSceneLuaObj, "场景未绑定LUA对象")
	oSceneLuaObj:OnObjEnterScene(oGameNativeObj)
end

--@bKick 场景销毁时会将所有场景中的游戏对象移出场景
function OnObjLeaveScene(oSceneNativeObj, oGameNativeObj, bKick)
	local oSceneLuaObj = oSceneNativeObj:GetLuaObj()
	assert(oSceneLuaObj, "场景未绑定LUA对象")
	oSceneLuaObj:OnObjLeaveScene(oGameNativeObj, bKick)
end

--游戏对象进入观察者视野
function OnObjEnterObj(oSceneNativeObj, tObserver, tObserved)
	local oSceneLuaObj = oSceneNativeObj:GetLuaObj()
	assert(oSceneLuaObj, "场景未绑定LUA对象")
	oSceneLuaObj:OnObjEnterObj(tObserver, tObserved)
end

--游戏对象离开观察者视野
function OnObjLeaveObj(nSceneNativeObj, tObserver, tObserved)
	local oSceneLuaObj = oSceneNativeObj:GetLuaObj()
	assert(oSceneLuaObj, "场景未绑定LUA对象")
	oSceneLuaObj:OnObjLeaveObj(tObserver, tObserved)
end

--游戏对象到达指定坐标
function OnObjReachTargetPos(oSceneNativeObj, oGameNativeObj, nPosX, nPosY)
	local oSceneLuaObj = oSceneNativeObj:GetLuaObj()
	assert(oSceneLuaObj, "场景未绑定LUA对象")
	oSceneLuaObj:OnObjReachTargetPos(oGameNativeObj, nPosX, nPosY)
end
