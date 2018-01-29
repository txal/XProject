--邮件任务处理器
local nServerID = gnServerID
local tMysqlConf = gtMgrMysqlConf
local nLogicService = next(gtNetConf.tLogicService) --逻辑服ID

local nInterval = 3 --秒
function CMailTask:Ctor()
	self:Init()
end

function CMailTask:Init()
	self.m_oMgrMysql = MysqlDriver:new()
	self.m_nTick = goTimerMgr:Interval(nInterval, function() self:OnTimer() end)

	local bRes = self.m_oMgrMysql:Connect(tMysqlConf.sIP, tMysqlConf.nPort, tMysqlConf.sDBName, tMysqlConf.sUserName, tMysqlConf.sPassword, "utf8")
	assert(bRes, "连接数据库失败: "..table.ToString(tMysqlConf, true))
	LuaTrace("连接数据库成功:", tMysqlConf)
end

function CMailTask:LoadData()
end

function CMailTask:SaveData()
end

function CMailTask:OnRelease()
	goTimerMgr:Clear(self.m_nTick)
	self.m_nTick = nil
end

function CMailTask:OnTimer()
	local nNowSec = os.time()
	local sSql = "select id,title,content,receiver,itemlist from sendmail where serverid=%d and state=0 and sendtime<=%d;"
	sSql = string.format(sSql, nServerID, nNowSec)
	if not self.m_oMgrMysql:Query(sSql) then
		return
	end
	local sUpdateSql = "update sendmail set state=1 where id=%d;"
	while self.m_oMgrMysql:FetchRow() do
		local nID = self.m_oMgrMysql:ToInt32("id")
		local sTitle, sContent, sReceiver, sItemList = self.m_oMgrMysql:ToString("title", "content", "receiver", "itemlist")
		local itemlist = cjson.decode(sItemList)
		local target = sReceiver ~= "" and tonumber(sReceiver) or nil
		local tData = {title=sTitle, content=sContent, itemlist=itemlist, target=target}
		Srv2Srv.GMSendMailReq(nLogicService, 0, tData)
		self.m_oMgrMysql:Query(string.format(sUpdateSql, nID))
	end
end

goMailTask = goMailTask or CMailTask:new()
