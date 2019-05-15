--数据库管理模块
function CDBMgr:Ctor()
	self.m_tNewSSDBMap = {} --新版数据库管理
	self.m_oMgrMysql = nil
	self.m_nUpdateTimer = nil
end

function CDBMgr:OnRelease()
	goTimerMgr:Clear(self.m_nUpdateTimer)
	self.m_nUpdateTimer = nil
end

function CDBMgr:ConnDB(nServerID, sDBName, nIdentID, sAddr)
	self.m_tNewSSDBMap[nServerID] = self.m_tNewSSDBMap[nServerID] or {}
	self.m_tNewSSDBMap[nServerID][sDBName] = self.m_tNewSSDBMap[nServerID][sDBName] or {}
	local tOldDB = self.m_tNewSSDBMap[nServerID][sDBName][nIdentID] 
	if tOldDB and tOldDB.sAddr == sAddr then
		return
	end

	local tAddr = string.Split(sAddr, "|")
	local oSSDB = SSDBDriver:new()
	local bRes = xpcall(function() oSSDB:Connect(tAddr[1], tonumber(tAddr[2])) end, function(sErr) LuaTrace(sErr) end)
	if bRes then
	    LuaTrace("连接"..sDBName.."成功:", tAddr)
	    local bAuth = true
	    if tAddr[3] then
	    	bAuth = oSSDB:Auth(tAddr[3])
	    end
	    if bAuth then
		    self.m_tNewSSDBMap[nServerID][sDBName][nIdentID] = {oSSDB=oSSDB, sAddr=sAddr}
		end
	end
end

function CDBMgr:InitNew()
	goTimerMgr:Clear(self.m_nUpdateTimer)
	self.m_nUpdateTimer = nil
	
	if not self.m_oMgrMysql then
		local tConf = gtMgrSQL
		local oMgrMysql = MysqlDriver:new() 
		local bRes = oMgrMysql:Connect(tConf.ip, tConf.port, tConf.db, tConf.usr, tConf.pwd, "utf8")
		assert(bRes, "连接数据库失败"..tostring(tConf))
		self.m_oMgrMysql = oMgrMysql
	end
	if gnServerID < gnWorldServerID then --本地服
		-- self.m_oMgrMysql:Query("select serverid,centerdb,userdb,localglobaldb from serverlist where serverid="..gnServerID)
		self.m_oMgrMysql:Query(string.format("select serverid,centerdb,userdb from serverlist where serverid=%d;", gnServerID))
		assert(self.m_oMgrMysql:FetchRow(), "服务器配置不存在:"..gnServerID)

		-- local centerdb, userdb, localglobaldb = self.m_oMgrMysql:ToString("centerdb", "userdb", "localglobaldb")
		local centerdb, userdb = self.m_oMgrMysql:ToString("centerdb", "userdb")
		self:ConnDB(0, "center", 1, centerdb)
		self:ConnDB(gnServerID, "user", 1, userdb)
		self:ConnDB(gnServerID, "global", 20, userdb)

	else
		assert(gnGroupID > 0, "世界服组ID错误")
		-- self.m_oMgrMysql:Query("select serverid,centerdb,userdb,worldglobaldb,worldglobaldb2 from serverlist where groupid="..gnGroupID)
		self.m_oMgrMysql:Query(string.format("select serverid,centerdb,userdb,worldglobaldb from serverlist where groupid=%d;", gnGroupID))
		while self.m_oMgrMysql:FetchRow() do
			local localserverid = self.m_oMgrMysql:ToInt32("serverid")
			-- local centerdb, userdb, worldglobaldb, worldglobaldb2 = self.m_oMgrMysql:ToString("centerdb", "userdb", "worldglobaldb", "worldglobaldb2")
			local centerdb, userdb, worldglobaldb = self.m_oMgrMysql:ToString("centerdb", "userdb", "worldglobaldb")
			self:ConnDB(0, "center", 1, centerdb)
			self:ConnDB(localserverid, "user", 1, userdb)
			self:ConnDB(gnServerID, "global", 110, worldglobaldb)
			self:ConnDB(gnServerID, "global", 111, worldglobaldb)
		end
	end

	self.m_nUpdateTimer = goTimerMgr:Interval(60, function() self:InitNew() end)
end

--通过SSDB名字取SSDB
--@nIdentID user数据库要传角色ID; global数据库要传服务ID
function CDBMgr:GetSSDB(nServer, sDBName, nIdentID)
	assert(nServer and sDBName, "参数错误")
	nIdentID = nIdentID or 1
	if sDBName == "user" then
		nIdentID = 1
	end
    self.m_tNewSSDBMap[nServer] = self.m_tNewSSDBMap[nServer] or {}
    self.m_tNewSSDBMap[nServer][sDBName] = self.m_tNewSSDBMap[nServer][sDBName] or {}

	local oSSDB = self.m_tNewSSDBMap[nServer][sDBName][nIdentID].oSSDB
	assert(oSSDB, "SSDB不存在:server:"..nServer.." dbname:"..sDBName.." ident:"..nIdentID)
	return oSSDB
end

--取后台MYSQL连接
function CDBMgr:GetMgrMysql()
	return self.m_oMgrMysql
end

goDBMgr = goDBMgr or CDBMgr:new()
