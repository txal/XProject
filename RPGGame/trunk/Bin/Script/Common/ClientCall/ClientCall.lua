--客户端远程调用(通知客户端弹框并等待回调用)
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert
local _time = os.time
local _assert = assert
local _clock = os.clock
local _co_yield = coroutine.yield
local _co_create = coroutine.create
local _co_resume = coroutine.resume
local _co_status = coroutine.status

local function fnCompare(t1, t2)
	if t1.nExpireTime > t2.nExpireTime then
		return 1
	end
	if t1.nExpireTime < t2.nExpireTime then
		return -1
	end
	return 0
end

--协程过期时间
local nDefaultExpireTime = 180
function CClientCall:Ctor()
	self.m_nCallID = 0
	self.m_tCoroutineMap = {}
	self.m_oMinHeap = CMinHeap:new(fnCompare)
	self.m_nTimer = nil
end

--初始化
function CClientCall:Init(nServiceID)
	assert(nServiceID > 0, "服务ID错误")
	self.m_nServiceID = nServiceID
	self.m_nTimer = goTimerMgr:Interval(2, function() self:CheckExpire() end)
end

function CClientCall:OnRelease()
	goTimerMgr:Clear(self.m_nTimer)
	self.m_nTimer = nil
end

function CClientCall:GenCallID()
	self.m_nCallID = self.m_nCallID % 0xFFFF + 1
	local nCallID = self.m_nServiceID<<16|self.m_nCallID
	return nCallID
end

function CClientCall:GetCoroutine(nCallID)
	return self.m_tCoroutineMap[nCallID]
end

--协程体
local function fnCoroutineFunc(nCallID, sCallFunc, nTarServer, nTarSession, tMsg)
	tMsg.nCallID = nCallID
	tMsg.nService = GlobalExport.GetServiceID()
	tMsg.nTimeOut = tMsg.nTimeOut or nDefaultExpireTime --默认超时
	CmdNet.PBSrv2Clt(sCallFunc, nTarServer, nTarSession, tMsg) 
	local nCode, tData = _co_yield(true)

	if nCode == 0 then
		print("协程执行成功:", nCallID, sCallFunc, "返回:", tData)

	elseif nCode == -1 then
		return LuaTrace("协程执行失败:", nCallID, sCallFunc, "返回:", tData)

	elseif nCode == -2 then
		return LuaTrace("协程执行超时:", nCallID, sCallFunc, tMsg.sCont)

	end
end

--请求客户端弹框(不需回调)
function CClientCall:Call(sCallFunc, oRole, tMsg) 
	tMsg.nService = GlobalExport.GetServiceID()
	tMsg.nTimeOut = tMsg.nTimeOut or nDefaultExpireTime --默认超时
	CmdNet.PBSrv2Clt(sCallFunc, oRole:GetServer(), oRole:GetSession(), tMsg) 
end

--请求客户端弹框(需要回调)：请求发出后协程会挂起，等待回调
--@sCallFunc: 远程函数名
--@fnCallback: 回调函数
function CClientCall:CallWait(sCallFunc, fnCallback, oRole, tMsg) 
	_assert(self.m_nTimer > 0, "初始化后才能使用")
	_assert(sCallFunc and oRole and tMsg, "参数错误")
	local nTarServer, nTarSession = oRole:GetServer(), oRole:GetSession()
	if nTarSession <= 0 then return end

	tMsg.nTimeOut = tMsg.nTimeOut or nDefaultExpireTime --默认超时
	local nExpireTime = _time() + tMsg.nTimeOut

	local nCallID = self:GenCallID()
	local oCo = _co_create(fnCoroutineFunc)
	self.m_tCoroutineMap[nCallID] = {oCo=oCo, nCallID=nCallID, sCallFunc=sCallFunc, fnCallback=fnCallback, nExpireTime=nExpireTime, nTimeOutSelIdx=(tMsg.nTimeOutSelIdx or 0)}

	local tVal = {nCallID=nCallID, nExpireTime=nExpireTime+2}--(+2)防止客户端到时发消息过来服务器协程已超时被清理
	self.m_oMinHeap:Push(tVal)
	local bRes, sErr = _co_resume(oCo, nCallID, sCallFunc, nTarServer, nTarSession, tMsg) 
	if not bRes then
		LuaTrace(sErr)
	end
end

--客户端确认返回
function CClientCall:OnCallRet(nSrcServer, nTarSession, nCallID, tData) 
	local tCo = self.m_tCoroutineMap[nCallID]
	if not tCo then
	    CmdNet.PBSrv2Clt("TipsMsgRet", nSrcServer, nTarSession, {sCont="操作超时"})
	    return LuaTrace("CClientCall:OnCallRet协程已超时:", nCallID)
	end

	local bRet, sErr = _co_resume(tCo.oCo, 0, tData)
	_assert(_co_status(tCo.oCo)=="dead")
	self.m_tCoroutineMap[nCallID] = nil

	if not bRet then
		LuaTrace("CClientCall:OnCallRet协程回调错误:", nCallID, tCo.sCallFunc, sErr)

	elseif tCo.fnCallback then
		tCo.fnCallback(tData)

	end
end

--清理超时协程
function CClientCall:CheckExpire()
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
				LuaTrace("CClientCall协程超时错误:", tCo.nCallID, tCo.sCallFunc, sErr)

			elseif tCo.nTimeOutSelIdx > 0 then
				tCo.fnCallback({nSelIdx=tCo.nTimeOutSelIdx}) --超时默认选择

			end
		else
			self.m_oMinHeap:RemoveByValue(tVal)
			
		end

	end
end

goClientCall = goClientCall or CClientCall:new()