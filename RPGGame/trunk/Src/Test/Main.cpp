#include "Common/MGHttp/HttpClient.h"
#include "Common/DataStruct/Thread.h"
#include <iostream>
using namespace std;


static const char *url = "http://127.0.0.1:130/test.php";

Thread thread;
HttpClient client;


void worker(void* param)
{
	while (true)
	{
		HTTPMSG* pMsg = client.GetResponse();
		if (pMsg != NULL)
		{
			cout << pMsg->data.c_str() << endl;
			SAFE_DELETE(pMsg);
		}
		Sleep(1000);
	}
}

int main(void) {
	thread.Create(worker, NULL);
	client.Init();
	while (true)
	{
		HTTPMSG* pMsg = XNEW(HTTPMSG);
		pMsg->url = url;
		pMsg->data = "{\"a\":\"1\",\"b\":\"2\"}";
		client.HttpPost(pMsg);
		Sleep(1000);
		break;
	}
	getchar();
	return 0;
}