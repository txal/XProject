--服务器内部远程同步调用
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

local function fnCompare(v1, v2)
	local oCo1 = goRemoveCall:GetCoroutine(v1)
	local oCo2 = goRemoveCall:GetCoroutine(v2)
	if oCo1.nExpireTime > oCo2.nExpireTime then
		return 1
	end
	if oCo1.nExpireTime > oCo2.nExpireTime then
		return -1
	end
	return 0
end

--3秒超时
local nExpireTime = 3
function CRemoteCall:Ctor()
	self.m_nCallID = 0
	self.m_tCoroutineMap = {}
	self.m_oMinHeap = CMinHeap:new(fnCompare)
	self.m_nTimer = goTimerMgr:Interval(3, function() self:CheckExpire() end)
end

function CRemoteCall:OnRelease()
	goTimerMgr:Clear(self.m_nTimer)
	self.m_nTimer = nil
end

function CRemoteCall:GenCallID()
	self.m_nCallID = self.m_nCallID % nMAX_INTERGER + 1
	return self.m_nCallID
end

function CRemoteCall:GetCoroutine(nCallID)
	return self.m_tCoroutineMap[nCallID]
end

local function _CoroutineFunc(nCallID, sCallFunc, fnCallBack, nTarServer, nTarService, nTarSession, ...)
	Srv2Srv.RemoveCallReq(nTarServer, nTarService, nTarSession, nCallID, sCallFunc, true, ...)
	local nCode, tData = coroutine.yield(true)

	if nCode == 0 then
		LuaTrace("协程执行成功:", nCallID, sCallFunc)
		fnCallBack(table.unpack(tData))

	elseif nCode == -1 then
		return LuaTrace("协程执行失败:", nCallID, sCallFunc, table.unpack(tData))

	elseif nCode == -2 then
		return LuaTrace("协程执行超时:", nCallID, sCallFunc)

	end
end

--远程调用请求(不需返回)
function CRemoteCall:Call(sCallFunc, nTarServer, nTarService, nTarSession, ...)
	Srv2Srv.RemoveCallReq(nTarServer, nTarService, nTarSession, 0, sCallFunc, false, ...)
end

--远程调用请求(需要返回)
function CRemoteCall:CallWait(sCallFunc, fnCallBack, nTarServer, nTarService, nTarSession, ...)
	assert(sFunc and nTarServer and nTarService, "参数错误")
	nTarSession = nTarSession or 0
	local nCallID = self:GenCallID()
	local oCo = coroutine.create(_CoroutineFunc)
	self.m_tCoroutineMap[nCallID] = {oCo=oCo, nExpireTime=os.time()+3}
	self.m_oMinHeap.Push(nCallID)
	coroutine.resume(oCo, nCallID, sCallFunc, fnCallBack, nTarServer, nTarService, nTarSession, ...)
end

--远程调用返回
function CRemoteCall:OnCallRet(nTarSession, nCallID, nCode, ...) 
	local tCo = self.m_tCoroutineMap[nCallID]
	if not tCo then
		return LuaTrace("协程不存在:", nCallID)
	end
	local tData = {...}
	local bRet, sErr = coroutine.resume(tCo.oCo, nCode, tData)
	if not bRet then
		LuaTrace("OnCallRet:", sErr)
	end
	assert(coroutine.status(tCo.oCo) == "dead")
	self.m_tCoroutineMap[nCallID] = nil
end

--清理超时协程
function CRemoteCall:CheckExpire()
	local nNowSec = os.time()
	while true do
		local nCallID = self.m_oMinHeap:Min()
		if not nCallID then
			break
		end

		local tCo = self.m_tCoroutineMap[nCallID]
		if tCo then
			if nNowSec < tCo.nExpireTime then
				break
			end
			local bRet, sErr = coroutine.resume(tCo.oCo, -2)
			if not bRet then
				LuaTrace("CheckExpire:", sErr)
			end
			assert(coroutine.status(tCo.oCo) == "dead")
			self.m_tCoroutineMap[nCallID] = nil

		else
			self.m_oMinHeap:RemoveByValue(nCallID)

		end
	end
end