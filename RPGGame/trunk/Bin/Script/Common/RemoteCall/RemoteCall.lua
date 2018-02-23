--服务器内部远程调用
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

local function fnCompare(t1, t2)
	if t1.nExpireTime > t2.nExpireTime then
		return 1
	end
	if t1.nExpireTime < t2.nExpireTime then
		return -1
	end
	return 0
end

--超时时间
local nExpireTime = 2
function CRemoteCall:Ctor()
	self.m_nCallID = 0
	self.m_tCoroutineMap = {}
	self.m_oMinHeap = CMinHeap:new(fnCompare)
	self.m_nTimer = nil
end

--初始化
function CRemoteCall:Init()
	self.m_nTimer = goTimerMgr:Interval(3, function() self:CheckExpire() end)
end

function CRemoteCall:OnRelease()
	goTimerMgr:Clear(self.m_nTimer)
	self.m_nTimer = nil
end

function CRemoteCall:GenCallID()
	self.m_nCallID = self.m_nCallID % nMAX_INTEGER + 1
	return self.m_nCallID
end

function CRemoteCall:GetCoroutine(nCallID)
	return self.m_tCoroutineMap[nCallID]
end

--协程体
local function fnCoroutineFunc(nCallID, sCallFunc, fnCallback, nTarServer, nTarService, nTarSession, ...)
	Srv2Srv.RemoteCallReq(nTarServer, nTarService, nTarSession, nCallID, sCallFunc, true, ...)
	local nCode, tData = coroutine.yield(true)

	if nCode == 0 then
		LuaTrace("协程执行成功:", nCallID, sCallFunc, "返回:", tData)
		if fnCallback then
			fnCallback(table.unpack(tData))
		end

	elseif nCode == -1 then
		return LuaTrace("协程执行失败:", nCallID, sCallFunc, "返回:", table.unpack(tData))

	elseif nCode == -2 then
		return LuaTrace("协程执行超时:", nCallID, sCallFunc)

	end
end

--远程调用请求(不需返回)：请求发出，不需要等待返回
--@sCallFunc: 远程函数名
--@nTarServer: 目标服务器ID
--@nTarService: 目标服务ID
--@nTarSession: 目标会话ID
function CRemoteCall:Call(sCallFunc, nTarServer, nTarService, nTarSession, ...)
	Srv2Srv.RemoteCallReq(nTarServer, nTarService, nTarSession, 0, sCallFunc, false, ...)
end

--远程调用请求(需要返回)：请求发出后协程会挂起，等待返回，3秒钟超时
--@sCallFunc: 远程函数名
--@fnCallback: 回调函数
--@nTarServer: 目标服务器ID
--@nTarService: 目标服务ID
--@nTarSession: 目标会话ID
function CRemoteCall:CallWait(sCallFunc, fnCallback, nTarServer, nTarService, nTarSession, ...)
	assert(sCallFunc and nTarServer and nTarService, "参数错误")
	nTarSession = nTarSession or 0
	local nCallID = self:GenCallID()
	local oCo = coroutine.create(fnCoroutineFunc)
	self.m_tCoroutineMap[nCallID] = {oCo=oCo}
	local tVal = {nCallID=nCallID, nExpireTime=os.time()+nExpireTime}
	self.m_oMinHeap:Push(tVal)
	coroutine.resume(oCo, nCallID, sCallFunc, fnCallback, nTarServer, nTarService, nTarSession, ...)
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
		LuaTrace("CRemoteCall:OnCallRet:", nCallID, sErr)
	end
	assert(coroutine.status(tCo.oCo) == "dead")
	self.m_tCoroutineMap[nCallID] = nil
end

--清理超时协程
function CRemoteCall:CheckExpire()
	local nNowSec = os.time()
	while true do
		local tVal = self.m_oMinHeap:Min()
		if not tVal then
			break
		end

		local tCo = self.m_tCoroutineMap[tVal.nCallID]
		if tCo then
			if tVal.nExpireTime > nNowSec then
				break
			end
			local bRet, sErr = coroutine.resume(tCo.oCo, -2)
			if not bRet then
				LuaTrace("CRemoteCall:CheckExpire:", tVal.nCallID, sErr)
			end
			assert(coroutine.status(tCo.oCo) == "dead")
			self.m_tCoroutineMap[tVal.nCallID] = nil
		end
		self.m_oMinHeap:RemoveByValue(tVal)

	end
end

goRemoteCall = goRemoteCall or CRemoteCall:new()