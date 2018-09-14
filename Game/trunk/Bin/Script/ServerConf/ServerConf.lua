gnServerID = 1

gtNetConf = 
{
    tRouterServers  = {[11] = { sIP = "127.0.0.1", nPort = 5050 } },
    tGateServers = {[21] = { nPort = 7070, nMaxConn = 10000} },
    tGlobalServer   = {[31] = { nPort = 8080} },
    tLogServer      = {[41] = {} },
    tLogicServers   = {[51] = {} },
}

gtSSDBConf = 
{
    sIP = "192.168.1.33",
    nPort = 8300,
}

gtMysqlConf = 
{
    sIP = "192.168.1.33",
    nPort = 3306,
    sDBName = "Marine",
    sUserName = "root",
    sPassword = "111111",
}
