#include "HttpClient.h"
#include "Include/Logger/Logger.hpp"

struct UD
{
	int luaref ;
	HttpClient* httpclient;
};

HttpClient::HttpClient()
{
	m_bStop = true;
}
HttpClient::~HttpClient()
{
	Stop();
	while (m_oReqList.size() > 0)
	{
		SAFE_DELETE(m_oReqList.front());
		m_oReqList.pop();
	}
	while (m_oResList.size() > 0)
	{
		SAFE_DELETE(m_oResList.front());
		m_oResList.pop();
	}
}

bool HttpClient::Init()
{
	m_bStop = false;
	mg_mgr_init(&m_oMGMgr, NULL);
	return m_oThread.Create(HttpClient::WorkerThread, this);
}

void HttpClient::Stop()
{
	m_bStop = true;
}

HTTPMSG* HttpClient::GetResponse()
{
	HTTPMSG* poRes = NULL;
	m_oResLock.Lock();
	if (m_oResList.size() > 0)
	{
		poRes = m_oResList.front();
		m_oResList.pop();
	}
	m_oResLock.Unlock();
	return poRes;
}

void HttpClient::HttpGet(HTTPMSG* pMsg)
{
	if (m_bStop)
	{
		SAFE_DELETE(pMsg);
		return;
	}
	pMsg->type = 1;
	m_oReqLock.Lock();
	m_oReqList.push(pMsg);
	m_oReqLock.Unlock();
}

void HttpClient::HttpPost(HTTPMSG* pMsg)
{
	if (m_bStop)
	{
		SAFE_DELETE(pMsg);
		return;
	}
	pMsg->type = 2;
	m_oReqLock.Lock();
	m_oReqList.push(pMsg);
	m_oReqLock.Unlock();
}

void HttpClient::ev_handler(struct mg_connection *c, int ev, void *p, void* userdata)
{
	UD* pUD = (UD*)userdata;
	HttpClient* pClient = pUD->httpclient;

	if (ev == MG_EV_HTTP_REPLY) {
		struct http_message *hm = (struct http_message *)p;
		c->flags |= MG_F_CLOSE_IMMEDIATELY;

		HTTPMSG* poRes = XNEW(HTTPMSG)();
		poRes->data = std::string(hm->body.p, hm->body.len);
		poRes->luaref = pUD->luaref;
		pUD->luaref = LUA_NOREF;

		pClient->m_oResLock.Lock();
		pClient->m_oResList.push(poRes);
		pClient->m_oResLock.Unlock();
	}
	else if (ev == MG_EV_CLOSE)
	{
		SAFE_DELETE(pUD);
	}
}

void HttpClient::ProcessRequest()
{
	m_oReqLock.Lock();
	while (m_oReqList.size() > 0)
	{
		HTTPMSG* pMsg = m_oReqList.front();
		m_oReqList.pop();

		UD* pUD = XNEW(UD)();
		pUD->httpclient = this;
		pUD->luaref = pMsg->luaref;
		pMsg->luaref = LUA_NOREF;

		if (pMsg->type == 1)
		{
			mg_connect_http(&m_oMGMgr, ev_handler, pUD, pMsg->url.c_str(), NULL, NULL);
		}
		else
		{
			mg_connect_http(&m_oMGMgr, ev_handler, pUD, pMsg->url.c_str(), "Content-Type: application/x-www-form-urlencoded\r\n", pMsg->data.c_str());
		}

		SAFE_DELETE(pMsg);
	}
	m_oReqLock.Unlock();
}

void HttpClient::WorkerThread(void* param)
{
	HttpClient* pClient = (HttpClient*)param;
	while (!pClient->m_bStop)
	{
		mg_mgr_poll(&pClient->m_oMGMgr, 10);
		pClient->ProcessRequest();
	}
	mg_mgr_free(&pClient->m_oMGMgr);
}

