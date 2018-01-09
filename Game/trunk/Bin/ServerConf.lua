gnServerID = 1 --[1-100]:测试服; [10001-65535]:正式服

gtNetConf = 
{
    tRouterService  = {[11] = { sIP = "127.0.0.1", nPort = 8100 } },
    tGateService    = {[21] = { nPort = 8200, nMaxConn = 10000} },  --需要开放端口
    tGlobalService  = {[31] = { nPort = 8300} },                    --需要开放端口
    tLogService     = {[41] = {} },
    tLogicService   = {[51] = {} },

    GetGlobalService = function(self) return next(self.tGlobalService) end,
}

--游戏ssdb
gtSSDBConf = 
{
    sIP = "127.0.0.1",
    nPort = 8500,
}

--游戏mysql(需要开放端口)
gtGameMysqlConf = 
{
    sIP = "192.168.1.11",
    nPort = 3306,
    sDBName = "marine_s"..gnServerID,
    sUserName = "root",
    sPassword = "123456",
}

--充值mysql(需要开放端口)
gtRechargeMysqlConf = 
{
    sIP = "192.168.1.11",
    nPort = 3306,
    sDBName = "marine_gm",
    sUserName = "root",
    sPassword = "123456",
}

--Http:8800
