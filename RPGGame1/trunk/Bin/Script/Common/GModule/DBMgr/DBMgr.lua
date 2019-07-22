--数据库管理模块
function CDBMgr:Ctor()
	CGModuleBase.Ctor(self, gtGModuleDef.tDBMgr)

	self.m_tGameDBMap = {}
	self.m_oMgrMysql = nil
end

function CDBMgr:Init()
	if not self.m_oMgrMysql then
		local tConf = gtMgrSQL
		local oMgrMysql = MysqlDriver:new() 
		local bRes = oMgrMysql:Connect(tConf.ip, tConf.port, tConf.db, tConf.usr, tConf.pwd, "utf8")
		assert(bRes, "连接数据库失败"..tostring(tConf))
		self.m_oMgrMysql = oMgrMysql
	end
	if gnServerID < gnWorldServerID then --本地服
		self.m_oMgrMysql:Query(string.format("select serverid,centerdb,userdb from serverlist where serverid=%d;", gnServerID))
		assert(self.m_oMgrMysql:FetchRow(), "服务器配置不存在:"..gnServerID)

		local centerdb, userdb = self.m_oMgrMysql:ToString("centerdb", "userdb")
		self:_ConnDB(0, "center", 1, centerdb)
		self:_ConnDB(gnServerID, "user", 1, userdb)
		self:_ConnDB(gnServerID, "global", 20, userdb)

	else
		assert(gnGroupID > 0, "世界服组ID错误")
		self.m_oMgrMysql:Query(string.format("select serverid,centerdb,userdb,worldglobaldb from serverlist where groupid=%d;", gnGroupID))
		while self.m_oMgrMysql:FetchRow() do
			local nLocalServerID = self.m_oMgrMysql:ToInt32("serverid")
			local sCenterDB, sUserDB, sWorldGlobalDB = self.m_oMgrMysql:ToString("centerdb", "userdb", "worldglobaldb")
			self:_ConnDB(0, "center", 1, sCenterDB)
			self:_ConnDB(nLocalServerID, "user", 1, sUserDB)
			self:_ConnDB(gnServerID, "global", 110, sWorldGlobalDB)
			self:_ConnDB(gnServerID, "global", 111, sWorldGlobalDB)
		end
	end
end

--连接数据库
function CDBMgr:_ConnDB(nServerID, sDBName, nIdentID, sAddr)
	self.m_tGameDBMap[nServerID] = self.m_tGameDBMap[nServerID] or {}
	self.m_tGameDBMap[nServerID][sDBName] = self.m_tGameDBMap[nServerID][sDBName] or {}
	self.m_tGameDBMap[nServerID][sDBName][nIdentID] = self.m_tGameDBMap[nServerID][sDBName][nIdentID] or {}

	local tOldDB = self.m_tGam3DBMap[nServerID][sDBName][nIdentID] 
	if tOldDB and tOldDB.sAddr == sAddr then
		return
	end

	local tAddr = string.Split(sAddr, "|")
	local oGameDB = SSDBDriver:new()
	local bRes = xpcall(function() oGameDB:Connect(tAddr[1], tonumber(tAddr[2])) end, function(sErr) LuaTrace(sErr) end)
	if bRes then
	    LuaTrace("连接"..sDBName.."成功:", tAddr)
	    local bAuth = true
	    if tAddr[3] then
	    	bAuth = oGameDB:Auth(tAddr[3])
	    end
	    if bAuth then
		    self.m_tGameDBMap[nServerID][sDBName][nIdentID] = {oGameDB=oGameDB, sAddr=sAddr}
		end
	end
end

--通过数据库名字取数据库对象(user, global)
--@nIdentID user数据库要传角色ID; global数据库要传服务ID
function CDBMgr:GetGameDB(nServer, sDBName, nIdentID)
	assert(nServer and sDBName, "参数错误")
	nIdentID = nIdentID or 1
	if sDBName == "user" then
		nIdentID = 1
	end
    self.m_tGameDBMap[nServer] = self.m_tGameDBMap[nServer] or {}
    self.m_tGameDBMap[nServer][sDBName] = self.m_tGameDBMap[nServer][sDBName] or {}
	self.m_tGameDBMap[nServer][sDBName][nIdentID] = self.m_tGameDBMap[nServer][sDBName][nIdentID] or {}

	local oGameDB = self.m_tGameDBMap[nServer][sDBName][nIdentID].oGameDB
	assert(oGameDB, "GameDB不存在:server:"..nServer.." dbname:"..sDBName.." ident:"..nIdentID)
	return oGameDB
end

--取后台MYSQL数据库对象
function CDBMgr:GetMgrMysql()
	return self.m_oMgrMysql
end

--整分计时器
function CDBMgr:OnMinTimer()
	self:Init()
end
