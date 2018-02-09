--远程调用
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

local function fnCompare(v1, v2)
	if v1 > v2 then
		return 1
	end
	if v1 < v2 then
		return -1
	end
	return 0
end

--3秒超时
local nExpireTime = 3
function CRemoteCall:Ctor()
	self.m_nCallIndex = 0
	self.m_tCoroutineMap = {}
	self.m_oMinHeap = CMinHeap:new(fnCompare)
end

function CRemoteCall:GenID()
	self.m_nCallIndex = self.m_nCallIndex % nMAX_INTERGER + 1
	return self.m_nCallIndex
end

local function _CoroutineFunc(sFunc, nTarServer, nTarService, nTarSession, ...)
	Srv2Srv[sFunc](nTarServer, nTarService, nTarSession, ...)
	coroutine.yield()
end

function CRemoteCall:Call(sFunc, nTarServer, nTarService, nTarSession)
	assert(sFunc and nTarServer and nTarService, "参数错误")
	nTarSession = nTarSession or 0
	local co = coroutine.create()
end