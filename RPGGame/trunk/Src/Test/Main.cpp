#include "Common/MGHttp/HttpLua.hpp"
#include "Common/DataStruct/Thread.h"
#include "Common/DataStruct/XTime.h"
#include <iostream>
using namespace std;


static const char *url = "http://127.0.0.1:130/test.php";

Thread thread;

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
	thread.Create(worker, NULL);
	goHttpClient.Init();
	while (true)
	{
		HTTPMSG* pMsg = XNEW(HTTPMSG);
		pMsg->url = "http://watcher.hoodinn.com/api/sign?project=新梦诛&system=跨服组1&service=测试哈";
		pMsg->data = "";
		goHttpClient.HttpGet(pMsg);
		XTime::MSSleep(1000);
	}
	getchar();
	return 0;
}