//#include "Include/Logger/Logger.h"
//#include "Common/HttpRequest/HttpRequest.h"
//#include "Common/DataStruct/PureList.h"
//#include "Common/DataStruct/CircleQueue.h"
//#include "Common/DataStruct/TimeMonitor.h"
//#include "Common/DataStruct/Thread.h"
//#include "Include/Network/Network.hpp"

#include "Common/HttpServer/HttpServer.h"

#include <iostream>
using namespace std;

HttpServer server;
void fnThread(void* param)
{
	for (;;)
	{
		HTTPMSG* pMsg = server.GetRequest();
		if (pMsg == NULL)
		{
			Sleep(10);
			continue;
		}
		server.Response(pMsg);
	}
}

int main(void) {
	server.Init("127.0.0.1:8000");
	Thread oThread;
	oThread.Create(fnThread, NULL);
	getchar();
	return 0;
}