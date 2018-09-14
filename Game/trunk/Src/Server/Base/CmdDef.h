#ifndef __NETCMD_H__
#define __NETCMD_H__

#define CMD_MIN 1
#define CMD_MAX 65535

//消息类型(1-125)
namespace NSMsgType
{
   enum 
    {
        eLuaRpcMsg = CMD_MIN,    //Rpc消息标识
        eLuaCmdMsg,              //Cmd消息标识
    }; 
}

//系统指令(126-1024)
namespace NSSysCmd
{
    enum
    {
		eCMD_BEGIN = 126,

        ssRegServiceReq = 126,			//注册服务到Router
        ssRegServiceRet = 127,			//Router返回注册结果
        ssClientClose = 129,			//客户端断开(网关->游戏服务)
        ssServiceClose = 130,			//服务断开(路由->所有服务)

		ssKickClient = 135,				//踢玩家下线
		ssBroadcastGate = 136,			//广播网关指令

		ssClientIPReq = 137,			//客户端IP请求
		ssClientIPRet = 138,			//客户端IP返回

		eCMD_END = 1025,
    };
};

//客户端服务器自定义协议指令(1025-8000)
namespace NSCltSrvCmd
{
	enum
	{
		eCMD_BEGIN = 1025,

		ppPing= 1025,					    //客户端Ping

		ppKeepAlive = 1100,					//客户端心跳包
		cPlayerRun = 1110,					//玩家跑步
		cPlayerStopRun = 1111,				//玩家停止跑步
		sSyncActorPos = 1112,				//同步角色位置
		sBroadcastActorRun = 1113,			//广播角色跑步
		sBroadcastActorStopRun = 1114,		//广播角色停止跑步
		cActorHurted = 1117,				//角色受伤
		cActorDamage = 1118,				//角色伤害
		sBroadcastActorHurt = 1119,			//广播角色受伤/伤害

		sBroadcastActorDead = 1121,			//广播角色死亡
		sSyncActorHP = 1122,				//同步/广播角色血量

		sBroadcastRanking = 1145,			//排行榜广播
		cEveHurted = 1146,					//队长上上报物打物伤害

		ppActorStartAttack = 1150,			//角色开始攻击
		ppActorStopAttack = 1151,			//角色停止攻击

		eCMD_END = 8000,
	};

};

//客户端服务器Protobuf指令(8001-40000)
namespace NSCltSrvPBCmd
{
	enum
	{
		eCMD_BEGIN = 8001,
		eCMD_END = 40000,
	};
};

//服务器间指令(40001-50000)
namespace NSSrvSrvCmd
{
	enum
	{
		eCMD_BEGIN = 40001,
        ssSyncLogicService = 40001,   //同步玩家逻辑服
		eCMD_END = 50000,
	};

};

//浏览器服务器指令(50001-50100)
namespace NSBsrSrvCmd
{
	enum
	{
		eCMD_BEGIN = 50001,
		eCMD_END = 50100,
	};
}


#endif