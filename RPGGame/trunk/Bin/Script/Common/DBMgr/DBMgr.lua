--数据库管理模块

function CDBMgr:Ctor()
	self.m_tSSDBMap = {}	--{[name]=ssdb, ...}
end

function CDBMgr:Init()
	--清除旧数据
	self.m_tSSDBMap = {}

	--连接SSDB
	for _, tConf in ipairs(gtSSDBConf) do
		local oSSDB = SSDBDriver:new()
		local bRes = oSSDB:Connect(tConf.sIP, tConf.nPort)
		assert(bRes, "连接SSDB失败:", tConf)
	    LuaTrace("连接SSDB成功:", tConf)
	    self.m_tSSDBMap[tConf.sName] = oSSDB
	end
end

--通过SSDB名字取SSDB
function CDBMgr:GetSSDB(sDBName)
	return assert(self.m_tSSDBMap[sDBName], "找不到SSDB:"..sDBName)
end
