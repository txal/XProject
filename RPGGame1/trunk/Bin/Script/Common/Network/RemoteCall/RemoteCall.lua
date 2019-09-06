--服务器内部远程调用
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert
local _time = os.time
local _assert = assert
local _clock = os.clock
local _co_yield = coroutine.yield
local _co_create = coroutine.create
local _co_resume = coroutine.resume
local _co_status = coroutine.status

local function _fnCompare(t1, t2)
	if t1.nExpireTime > t2.nExpireTime then
		return 1
	end
	if t1.nExpireTime < t2.nExpireTime then
		return -1
	end
	return 0
end

--超时时间
local nExpireTime = 180
function CRemoteCall:Ctor()
	self.m_nCallID = 0
	self.m_nTimer = nil
	self.m_tCoroutineMap = {}
	self.m_oMinHeap = CMinHeap:new(_fnCompare)
end

--初始化
function CRemoteCall:Init()
	self.m_nServiceID = CUtil:GetServiceID()
	self.m_nTimer = GetGModule("TimerMgr"):Interval(2, function() self:CheckExpire() end)
end

function CRemoteCall:Release()
	GetGModule("TimerMgr"):Clear(self.m_nTimer)
end

function CRemoteCall:GenCallID()
	self.m_nCallID = self.m_nCallID % 0xFFFFFFFF + 1
	local nCallID = self.m_nServiceID<<16|self.m_nCallID
	return nCallID
end

function CRemoteCall:GetCoroutine(nCallID)
	return self.m_tCoroutineMap[nCallID]
end

--协程体
local function fnCoroutineFunc(nCallID, sCallFunc, nTarServerID, nTarServiceID, nTarSessionID, ...)
	Network.RpcSrv2Srv.RemoteCallReq(nTarServerID, nTarServiceID, nTarSessionID, nCallID, sCallFunc, true, ...)
	local nCode, tData = _co_yield(true)

	if nCode == 0 then
		-- LuaTrace("协程执行成功:", nCallID, sCallFunc, "返回:", tData)

	elseif nCode == -1 then
		return LuaTrace("协程执行失败:", nCallID, sCallFunc, nTarServerID, nTarServiceID, "返回:", tData)

	elseif nCode == -2 then
		return LuaTrace("协程执行超时:", nCallID, sCallFunc, nTarServerID, nTarServiceID)

	end
end

--远程调用请求(不需回调)：请求发出，不需要等待返回
--@sCallFunc: 远程函数名
--@nTarServerID: 目标服务器ID
--@nTarServiceID: 目标服务ID
--@nTarSessionID: 目标会话ID
function CRemoteCall:Call(sCallFunc, nTarServerID, nTarServiceID, nTarSessionID, ...)
	_assert((self.m_nTimer or 0) > 0, "初始化后才能使用")
	_assert(sCallFunc and nTarServerID>0 and nTarServiceID>0, "参数错误")
	
	if gnServerID == nTarServerID and nTarServiceID == CUtil:GetServiceID() then
		-- _assert(false, "同进程的不需要远程调用")
	end
	Network.RpcSrv2Srv.RemoteCallReq(nTarServerID, nTarServiceID, nTarSessionID, 0, sCallFunc, false, ...)
end

--远程调用请求(需要回调)：请求发出后协程会挂起，等待回调，2秒钟超时
--@sCallFunc: 远程函数名
--@nTarServerID: 目标服务器ID
--@nTarServiceID: 目标服务ID
--@nTarSessionID: 目标会话ID
function CRemoteCall:CallWait(sCallFunc, fnCallback, nTarServerID, nTarServiceID, nTarSessionID, ...)
	_assert(self.m_nTimer > 0, "初始化后才能使用")
	_assert(sCallFunc and nTarServerID>0 and nTarServiceID>0, "参数错误")

	if gnServerID == nTarServerID and nTarServiceID == CUtil:GetServiceID() then
		-- _assert(false, "同进程的不需要远程调用")
	end
	nTarSessionID = nTarSessionID or 0

	local nCallID = self:GenCallID()
	local oCo = _co_create(fnCoroutineFunc)
	local tCo = {oCo=oCo, nCallID=nCallID, sCallFunc=sCallFunc, fnCallback=fnCallback, nClock=0}
	self.m_tCoroutineMap[nCallID] = tCo

	local tVal = {nCallID=nCallID, nExpireTime=_time()+nExpireTime}
	self.m_oMinHeap:Push(tVal)

	local bRet, sErr = _co_resume(oCo, nCallID, sCallFunc, nTarServerID, nTarServiceID, nTarSessionID, ...)
	if not bRet then
		LuaTrace(sErr)
	end
end

--远程调用返回
function CRemoteCall:OnCallRet(nCallID, nCode, ...) 
	local tCo = self.m_tCoroutineMap[nCallID]
	if not tCo then
		return LuaTrace("协程不存在:", nCallID)
	end

	local tData = {...}
	local bRet, sErr = _co_resume(tCo.oCo, nCode, tData)
	_assert(_co_status(tCo.oCo) == "dead")
	self.m_tCoroutineMap[nCallID] = nil

	if bRet then
		if nCode == -1 then
			tCo.fnCallback() --错误回调
		elseif nCode == 0 then
			tCo.fnCallback(...) --成功回调
		else
			_assert(false, "状态码错误")
		end

	else
		LuaTrace("协程回调resume错误", nCallID, tCo.sCallFunc, sErr)

	end
end

--清理超时协程
function CRemoteCall:CheckExpire()
	local nNowSec = _time()
	while true do
		local tVal = self.m_oMinHeap:Min()
		if not tVal then break end

		local tCo = self.m_tCoroutineMap[tVal.nCallID]
		if tCo then
			if tVal.nExpireTime > nNowSec then
				break
			end
			
			self.m_oMinHeap:RemoveByValue(tVal)
			local bRet, sErr = _co_resume(tCo.oCo, -2)
			_assert(_co_status(tCo.oCo) == "dead")
			self.m_tCoroutineMap[tVal.nCallID] = nil

			if not bRet then
				LuaTrace("协程超时resume错误:", tCo.nCallID, tCo.sCallFunc, sErr)
			else
				tCo.fnCallback() --超时回调
			end
		else
			self.m_oMinHeap:RemoveByValue(tVal)
			
		end

	end
end
