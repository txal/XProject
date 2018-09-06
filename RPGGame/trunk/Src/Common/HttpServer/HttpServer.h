#ifndef __HTTP_SERVER_H__
#define __HTTP_SERVER_H__

#include "Common/HttpServer/mongoose.h"
#include "Common/DataStruct/MutexLock.h"
#include "Common/DataStruct/Thread.h"

struct HTTPMSG
{
	struct mg_connection *c;
	std::string data;
	std::string url;
	int8_t type;

	HTTPMSG(mg_connection* _c, std::string& _data, int8_t _type)
	{
		c = _c;
		data = _data;
		type = _type;
	}
};

class HttpServer
{
public:
	HttpServer();
	~HttpServer();

	bool Init(const char* addr);
	void Stop();

public:
	HTTPMSG* GetRequest();
	void Response(HTTPMSG* poRes);

protected:
	static void ev_handler(struct mg_connection *c, int ev, void *p, void* userdata);
	static void WorkerThread(void* param);
	void ProcessResponse();

private:
	DISALLOW_COPY_AND_ASSIGN(HttpServer);
	bool m_bStop;

	std::string m_oAddr;
	MutexLock m_oReqLock;
	MutexLock m_oResLock;
	std::queue<HTTPMSG*> m_oReqList;
	std::queue<HTTPMSG*> m_oResList;
	Thread m_oThread;

	struct mg_mgr m_oMGMgr;
	struct mg_connection* m_pMGConn;
};

#endif