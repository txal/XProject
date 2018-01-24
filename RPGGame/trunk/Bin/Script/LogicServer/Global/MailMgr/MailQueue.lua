--邮件队列(同时发大量邮件时使用)
local nMAILS_PERSEC = 10 --每秒发送邮件数量

function CMailQueue:Ctor()
	self.m_tQueue = {}	--{sender,title,content,item,receiver={}}, ...
	self.m_nTimer = nil
end

--加载没有发完的邮件
function CMailQueue:LoadData()
end

--保存没有发完的邮件
function CMailQueue:SaveData()
end

function CMailQueue:OnRelease()
	self:SaveData()
	self:CancelTimer()
end

--是否还有未发送完的邮件
function CMailQueue:HasMail()
	return #self.m_tQueue > 0
end

--发送邮件
function CMailQueue:PushMail(sSenderName, sTitle, sContent, tItems, tReceiver)
	assert(#tReceiver > 0, "邮件不能没有接收者")
	table.insert(self.m_tQueue, 1, {sSenderName, sTitle, sContent, tItems, tReceiver})
	self:CheckSendTimer()
end

--取消计时器
function CMailQueue:CancelTimer()
	if not self.m_nTimer then
		return
	end
	GlobalExport.CancelTimer(self.m_nTimer)
	self.m_nTimer = nil
end

--检测发送计时器
function CMailQueue:CheckSendTimer()
	if #self.m_tQueue == 0 then
		self:CancelTimer()
		return
	end
	if not self.m_nTimer then
		self.m_nTimer = GlobalExport.RegisterTimer(1000, function() self:DispatchMail() end)	
	end
end

--分发邮件
function CMailQueue:DispatchMail()
	local nSentCount = 0
	while #self.m_tQueue > 0 and nSentCount < nMAILS_PERSEC do
		local tQueue = self.m_tQueue[#self.m_tQueue]
		while #tQueue[5] > 0 and nSentCount < nMAILS_PERSEC do
			local sTarCharID = tQueue[5][#tQueue[5]]
			table.remove(tQueue[5])
			nSentCount = nSentCount + 1
			goMailMgr:SendMail(tQueue[1], tQueue[2], tQueue[3], tQueue[4], sTarCharID)
		end
		if #tQueue[5] <= 0 then
			table.remove(self.m_tQueue)
		end
	end
	self:CheckSendTimer()
end


goMailQueue = goMailQueue or CMailQueue:new()