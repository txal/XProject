#ifndef __NETCMD_H__
#define __NETCMD_H__

#define CMD_MIN 1
#define CMD_MAX 65535

//消息类型(1-125)
namespace NSMsgType
{
   enum 
    {
        eLuaRpcMsg = 1,		//Rpc消息标识
        eLuaCmdMsg = 2,		//Cmd消息标识
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
		ssClientLastPacketTimeRet = 139,//客户端最后包时间返回

		ssCloseServerReq = 140,		//关服请求
		ssPrepCloseServer = 141,	//关服准备
		ssImplCloseServer = 142,	//关服执行

		eCMD_END = 1025,
    };
};

//客户端服务器自定义协议指令(1025-8000)
namespace NSCltSrvCmd
{
	enum
	{
		eCMD_BEGIN = 1025,

		ppPing= 1025,					    //客户端PING

		ppKeepAlive = 1100,					//客户端心跳包
		cRoleStartRunReq = 1110,			//角色开始跑动请求
		cRoleStopRunReq = 1111,				//角色停止跑步请求
		sSyncActorPosRet = 1112,			//同步角色位置返回
		sActorStartRunRet = 1113,			//角色开始跑步返回(广播)
		sActorStopRunRet = 1114,			//角色停止跑步返回(广播)

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