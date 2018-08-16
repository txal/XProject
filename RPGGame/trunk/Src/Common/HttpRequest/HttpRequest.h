#ifndef __HTTP_REQUEST_H__
#define __HTTP_REQUEST_H__
#include "Include/Curl/Curl.hpp"

#include "Common/DataStruct/MutexLock.h"
#include "Common/DataStruct/Thread.h"
#include "Common/Platform.h"

struct MCURL
{
	CURL* curl;

	char buffer[1024];
	uint16_t offset;
	uint32_t index;

	std::string url;

	MCURL(CURL* _curl, uint32_t _index, const char* _url)
	{
		offset = 0;
		curl = _curl;
		index = _index;
		url = _url;
	}
};

class HttpRequest
{
public:
	HttpRequest();
	~HttpRequest();

	bool Init(int nWorker);
	void Stop();

	void Get(const char* pURL);
	void Post(const char* pURL, const char* pParam = "");

protected:
	MCURL* GenCurl(int nType, const char* pURL, const char* pParam); //nType: 1-Get; 2-Post
	static size_t RecvFunc(void* data, size_t size, size_t nmemb, void *userdata);
	static void WorkThread(void* pParam);

private:
	DISALLOW_COPY_AND_ASSIGN(HttpRequest);

	bool m_bStop;
	int m_nWorker;
	uint32_t m_nReqIndex;

	MutexLock m_oWorkLock;
	std::queue<MCURL*> m_oQueRequest;
	std::vector<Thread*> m_oVecThread;
};

#endif