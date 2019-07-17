#include "Common/MGHttp/HttpLua.hpp"
#include "Common/DataStruct/XThread.h"
#include "Common/DataStruct/XTime.h"
#include "Include/Network/NetAPI.h"
#include <iostream>
#include <unordered_map>
using namespace std;


static const char *url = "http://127.0.0.1:130/test.php";

XThread thread;

void worker(void* param)
{
	while (true)
	{
		HTTPMSG* pMsg = goHttpClient.GetResponse();
		if (pMsg != NULL)
		{
			cout << pMsg->data.c_str() << endl;
			SAFE_DELETE(pMsg);
		}
		XTime::MSSleep(1000);
	}
}

int main(void) {
	//thread.Create(worker, NULL);
	//goHttpClient.Init();
	//while (true)
	//{
	//	HTTPMSG* pMsg = XNEW(HTTPMSG);
	//	pMsg->url = "http://watcher.hoodinn.com/api/sign?project=新梦诛&system=跨服组1&service=测试哈";
	//	pMsg->data = "";
	//	goHttpClient.HttpGet(pMsg);
	//	XTime::MSSleep(1000);
	//}
	//int nMSTimeOut = 10000;
	//struct timeval tv = { (long)(nMSTimeOut / 1000), (long)((nMSTimeOut % 1000) * 1000) };
	//select(0, NULL, NULL, NULL, &tv);

	int nSize = 1024;
	char* data = new char[nSize];
	memset(data, 1, nSize);

	int nSleepTime = 0;
	int nLastSendTime = time(NULL);

	unordered_map<HSOCKET, int8_t> mapSock;
	typedef unordered_map<HSOCKET, int8_t>::iterator sockIter;

	NetAPI::StartupNetwork();
	while(true)
	{
		if (nSleepTime > 0)
		{
			XTime::MSSleep(nSleepTime);
		}
		HSOCKET hSock = NetAPI::CreateTcpSocket();
		if (hSock == INVALID_SOCKET)
		{
			cout << "创建句柄失败" << endl;
			continue;
		}
		//if (!NetAPI::Connect(hSock, "114.55.199.62", 8502))
		if (!NetAPI::Connect(hSock, "192.168.35.250", 37001))
		{
			cout << "连接失败" << endl;
			NetAPI::CloseSocket(hSock);
			nSleepTime = 10000;
			continue;
		}
		nSleepTime = 0;
		mapSock[hSock] = 1;
		cout << "连接成功:" << mapSock.size() << endl;

		if (time(NULL) - nLastSendTime >= 10)
		{
			nLastSendTime = time(NULL);
			sockIter iter = mapSock.begin();
			for (iter; iter != mapSock.end(); )
			{
				int ret = send(iter->first, data, nSize, 0);
				if (ret <= 0)
				{
					NetAPI::CloseSocket(iter->first);
					iter = mapSock.erase(iter);
					cout << "发送失败:" << mapSock.size() << endl;
				}
				else
				{
					iter++;
				}
			}
		}
	}
	getchar();
	return 0;
}