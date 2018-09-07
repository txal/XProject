#include "HttpServer.h"
#include "Include/Logger/Logger.hpp"

HttpServer::HttpServer()
{
	m_bStop = true;
}
HttpServer::~HttpServer()
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

bool HttpServer::Init(const char* addr)
{
	m_oAddr = addr;
	mg_mgr_init(&m_oMGMgr, NULL);
	m_pMGConn = mg_bind(&m_oMGMgr, addr, HttpServer::ev_handler, (void*)this);
	mg_set_protocol_http_websocket(m_pMGConn);
	m_bStop = false;
	return m_oThread.Create(HttpServer::WorkerThread, this);
}

void HttpServer::Stop()
{
	m_bStop = true;
}

HTTPMSG* HttpServer::GetRequest()
{
	HTTPMSG* poReq = NULL;
	m_oReqLock.Lock();
	if (m_oReqList.size() > 0)
	{
		poReq = m_oReqList.front();
		m_oReqList.pop();
	}
	m_oReqLock.Unlock();
	return poReq;
}

void HttpServer::Response(HTTPMSG* poRes)
{
	if (m_bStop)
	{
		SAFE_DELETE(poRes);
		return;
	}
	m_oResLock.Lock();
	m_oResList.push(poRes);
	m_oResLock.Unlock();
}

void HttpServer::ev_handler(struct mg_connection *c, int ev, void *p, void* userdata)
{
	static char buff[1024];
	HttpServer* pServer = (HttpServer*)userdata;

	if (ev == MG_EV_HTTP_REQUEST) {
		struct http_message *hm = (struct http_message *) p;
		const char* get = strstr(hm->message.p, "GET");
		const char* post = strstr(hm->message.p, "POST");
		if (get != NULL)
		{
			int ret = mg_get_http_var(&hm->query_string, "data", buff, sizeof(buff));
			if (ret > 0 && buff[0] != '\0')
			{
				HTTPMSG* poReq = XNEW(HTTPMSG)();
				poReq->c = c;
				poReq->type = 1;
				poReq->data = std::string(buff);
				poReq->url = std::string(hm->uri.p, hm->uri.len);

				pServer->m_oReqLock.Lock();
				pServer->m_oReqList.push(poReq);
				pServer->m_oReqLock.Unlock();
			}
		}
		else if (post != NULL)
		{
			if (hm->body.len > 0)
			{
				HTTPMSG* poReq = XNEW(HTTPMSG)();
				poReq->c = c;
				poReq->type = 2;
				poReq->data = std::string(hm->body.p, hm->body.len);
				poReq->url = std::string(hm->uri.p, hm->uri.len);

				pServer->m_oReqLock.Lock();
				pServer->m_oReqList.push(poReq);
				pServer->m_oReqLock.Unlock();
			}
		}
		else
		{
			return;
		}
	}
}

void HttpServer::ProcessResponse()
{
	m_oResLock.Lock();
	while (m_oResList.size() > 0)
	{
		HTTPMSG* pMsg = m_oResList.front();
		m_oResList.pop();
		mg_send_head(pMsg->c, 200, pMsg->data.size(), "Content-Type: text/plain");
		mg_printf(pMsg->c, "%.*s", (int)pMsg->data.size(), pMsg->data.c_str());
		SAFE_DELETE(pMsg);
	}
	m_oResLock.Unlock();
}

void HttpServer::WorkerThread(void* param)
{
	HttpServer* pServer = (HttpServer*)param;
	while (!pServer->m_bStop)
	{
		mg_mgr_poll(&pServer->m_oMGMgr, 10);
		pServer->ProcessResponse();
	}
	mg_mgr_free(&pServer->m_oMGMgr);
}

