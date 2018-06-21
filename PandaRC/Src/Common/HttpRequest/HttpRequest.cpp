#include "HttpRequest.h"
#include "Include/Logger/Logger.h"
#include "Common/DataStruct/XMath.h"
#include "Common/DataStruct/XTime.h"

HttpRequest::HttpRequest()
{

}

HttpRequest::~HttpRequest()
{
	Stop();
}

bool HttpRequest::Init(int nWorker)
{
	m_bStop = false;
	m_nWorker = nWorker;
	m_nReqIndex = 0;

	CURLcode res = curl_global_init(CURL_GLOBAL_DEFAULT);
	if (res != CURLE_OK) 
	{
		XLog(LEVEL_ERROR, "Init curl fail:%s\n", curl_easy_strerror(res));
		return false;
	}

	for (int i = 0; i < m_nWorker; i++)
	{
		Thread* poThread = new Thread();
		if (!poThread->Create(HttpRequest::WorkThread, this, false))
		{
			XLog(LEVEL_ERROR, "Create thread fail\n");
			SAFE_DELETE(poThread);
			return false;
		}
		m_oVecThread.push_back(poThread);
	}
	return true;
}

void HttpRequest::Stop()
{
	m_bStop = true;
	for (int i = 0; i < m_oVecThread.size(); i++)
	{
		m_oVecThread[i]->Join();
		SAFE_DELETE(m_oVecThread[i]);
	}
	m_oVecThread.clear();

	while (m_oQueRequest.size() > 0)
	{
		MCURL* pMCURL = m_oQueRequest.front();
		curl_easy_cleanup(pMCURL->curl);
		SAFE_DELETE(pMCURL);
		m_oQueRequest.pop();
	}

	curl_global_cleanup();
}

void HttpRequest::Get(const char* pURL)
{
	MCURL* poMCURL = GenCurl(1, pURL, NULL);
	m_oWorkLock.Lock();
	m_oQueRequest.push(poMCURL);
	m_oWorkLock.Unlock();
}

void HttpRequest::Post(const char* pURL, const char* pParam)
{
	MCURL* poMCURL = GenCurl(2, pURL, pParam);
	m_oWorkLock.Lock();
	m_oQueRequest.push(poMCURL);
	m_oWorkLock.Unlock();
}

//nType: 1-Get; 2->Post
MCURL* HttpRequest::GenCurl(int nType, const char* pURL, const char* pParam)
{
	CURL* curl = curl_easy_init();
	MCURL* poMCURL = new MCURL(curl, ++m_nReqIndex, pURL);

	curl_easy_setopt(curl, CURLOPT_URL, poMCURL->url); //设置访问的URL

	if (nType == 2) //Post
	{
		curl_easy_setopt(curl, CURLOPT_POST, 1);
		if (pParam == NULL) pParam = "";
		curl_easy_setopt(curl, CURLOPT_POSTFIELDS, pParam); //post数据格式: a=1&b=2 或者 "" 不能是NULL,否则会卡住
	}

	//curl_easy_setopt(curl, CURLOPT_COOKIEFILE, "post.cookie");
	curl_easy_setopt(curl, CURLOPT_VERBOSE, 0); //是否打印调试信息:1是; 0否
	curl_easy_setopt(curl, CURLOPT_CONNECTTIMEOUT, 3);
	curl_easy_setopt(curl, CURLOPT_TIMEOUT, 6); //设置超时  
	curl_easy_setopt(curl, CURLOPT_NOSIGNAL, 1); //屏蔽其它信号  
	curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, 0);  //这两行一定要加,否则会报 SSL 错误
	curl_easy_setopt(curl, CURLOPT_SSL_VERIFYHOST, 0);
	curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, RecvFunc); //设置下载数据的回调函数  
	curl_easy_setopt(curl, CURLOPT_WRITEDATA, poMCURL);

	return poMCURL;
}

size_t HttpRequest::RecvFunc(void* data, size_t size, size_t num, void *userdata)
{
	int nTotalLen = (int)(size * num);
	MCURL* poMCURL = (MCURL*)userdata;
	int nCopyLen = XMath::Min(nTotalLen, (int)(sizeof(poMCURL->buffer) - poMCURL->offset));
	memcpy(poMCURL->buffer + poMCURL->offset, data, nCopyLen);
	poMCURL->offset += nCopyLen;
	return nTotalLen; //必须返回这个大小,否则只回调一次,不清楚为何.  
}

void HttpRequest::WorkThread(void* pParam)
{
	HttpRequest* poSelf = (HttpRequest*)pParam;

	while (!poSelf->m_bStop)
	{
		MCURL* poMCURL = NULL;
		poSelf->m_oWorkLock.Lock();
		if (poSelf->m_oQueRequest.size() > 0)
		{
			poMCURL = poSelf->m_oQueRequest.front();
			poSelf->m_oQueRequest.pop();
		}
		poSelf->m_oWorkLock.Unlock();
		if (poMCURL == NULL)
		{
			XTime::MSSleep(10);
			continue;
		}
		CURLcode res = curl_easy_perform(poMCURL->curl);
		curl_easy_cleanup(poMCURL->curl);

		if (res != CURLE_OK)
		{
			const char* pErr = curl_easy_strerror(res);
			XLog(LEVEL_ERROR, "[%d](%s) Curl request fail: %s\n", poMCURL->index, poMCURL->url, pErr);
		}
		else
		{
			int end = XMath::Min((int)(poMCURL->offset), (int)(sizeof(poMCURL->buffer) - 1));
			poMCURL->buffer[end] = '\0';
			printf("\n[%d]: [[--- %s ---]]\n", poMCURL->index, poMCURL->buffer);
		}
		//fix pd callback

		SAFE_DELETE(poMCURL);
	}
}

