gnServerID = 2 --[1-100]:测试服; [1001-32767]:正式服
gsServerName = "panda"
gbInnerServer = false

gtNetConf = 
{
    tRouterService  = {[11] = { sIP = "127.0.0.1", nPort = 8100 } },
    tGateService    = {[21] = {nPort=8101, nMaxConns=20000, nSecureCPM=120, nSecureQPM=180, nSecureBlock=60, nDeadLinkTime=120} },
    tGlobalService  = {[31] = { sIP = "192.168.3.182", nPort = 8102} },
    tLogService     = {[41] = { nWorkers=1, nMysqlConns=1 } },
    tLogicService   = {[51] = {} },

    LogService = function(self) return next(self.tLogService) end,
    GlobalService = function(self) return next(self.tGlobalService) end,
    LogicService = function(self) return next(self.tLogicService) end,
}


--SSDB
gtSSDBConf = 
{
    {sName = "Player", sIP = "127.0.0.1", nPort = 8103}, --PLAYER
    {sName = "Center", sIP = "192.168.0.9", nPort = 7500}, --CENTER
}

--游戏MYSQL
gtGameMysqlConf = 
{
    sIP = "192.168.0.9",
    nPort = 3308,
    sDBName = "taizifei_s"..gnServerID,
    sUserName = "root",
    sPassword = "123456",
}

--GM后台MYSQL
gtMgrMysqlConf = 
{
    sIP = "192.168.0.9",
    nPort = 3308,
    sDBName = "taizifei_mgr",
    sUserName = "root",
    sPassword = "123456",
}
