#ifndef __HTTP_CLIENT_H__
#define __HTTP_CLIENT_H__

#include "Common/MGHttp/mongoose.h"
#include "Common/DataStruct/MutexLock.h"
#include "Common/DataStruct/Thread.h"

class HttpClient
{
public:
	HttpClient();
	~HttpClient();

	void Stop();
	bool Init();

public:
	void HttpGet(HTTPMSG* pMsg);
	void HttpPost(HTTPMSG* pMsg);
	HTTPMSG* GetResponse();

protected:
	static void ev_handler(struct mg_connection *c, int ev, void *p, void* userdata);
	static void WorkerThread(void* param);
	void ProcessRequest();

private:
	DISALLOW_COPY_AND_ASSIGN(HttpClient);
	bool m_bStop;

	MutexLock m_oReqLock;
	MutexLock m_oResLock;
	std::queue<HTTPMSG*> m_oReqList;
	std::queue<HTTPMSG*> m_oResList;
	Thread m_oThread;

	struct mg_mgr m_oMGMgr;
};

#endif