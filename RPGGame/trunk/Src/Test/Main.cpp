#include "Include/Logger/Logger.h"
#include "Common/HttpRequest/HttpRequest.h"
#include "Common/DataStruct/PureList.h"
#include "Common/DataStruct/CircleQueue.h"
#include "Common/DataStruct/TimeMonitor.h";
#include "Common/DataStruct/Thread.h";
#include "Include/Network/Network.hpp"
#include <iostream>
using namespace std;

void OnSigTerm(int sig)
{
	printf("on sig term!!!:%d\n", sig);
}

int main()
{
	Logger::Instance()->Init();
	//const char* psCurl = "https://sandbox.itunes.apple.com/verifyReceipt";
	const char* psCurl = "http://sgadmin.df.baoyugame.com/yinghun/login.php";

	HttpRequest oHttp;
	oHttp.Init(2);
	for (int i = 0; i < 100; i++) {
		oHttp.Post(psCurl);
	}
	getchar();

	return 0;
}
