--全局模块定义(多个进程共用或者后面可能会拆到不同进程的模块)
gtGModuleDef = {}

--公共模块
gtGModuleDef.tDBMgr = {sName="DBMgr", cClass=CDBMgr, tServiceID={20,110,50,100}}
gtGModuleDef.tLogger = {sName="Logger", cClass=CLogger, tServiceID={20,110,50,100}}
gtGModuleDef.tTimerMgr = {sName="TimerMgr", cClass=CTimerMgr, tServiceID={20,110,50,100}}
gtGModuleDef.tServerMgr = {sName="ServerMgr", cClass=CServerMgr, tServiceID={20,110,50,100}}

--各自服务模块
gtGModuleDef.tLogMgr = {sName="LogMgr", cClass=CLogMgr, tServiceID={20}}
gtGModuleDef.tDupMgr = {sName="DupMgr", cClass=CDupMgr, tServiceID={50,100}}
gtGModuleDef.tRoleMgr = {sName="RoleMgr", cClass=CRoleMgr, tServiceID={50,100}}
gtGModuleDef.tLoginMgr = {sName="LoginMgr", cClass=CLoginMgr, tServiceID={20}}
gtGModuleDef.tGRoleMgr = {sName="GRoleMgr", cClass=CGRoleMgr, tServiceID={20,110}}
