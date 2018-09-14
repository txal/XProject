#include <stdio.h>
#include <sys/stat.h> 
#include <map>
#include <string>
#include <vector>
#include <iostream>
#include <unordered_map>
#include "Dirent.h"
#include "Common/DataStruct/Thread.h"
#include "Common/DataStruct/XTime.h"
#include "Include/Network/Network.hpp"

struct SCRIPT
{
	time_t nModTime;
	std::string oData;
	SCRIPT()
	{
		nModTime = 0;
	}
};
std::vector<std::string> goCmdVec;
std::string oScriptDir = "./Script";
std::unordered_map<std::string, SCRIPT> goScriptMgr;
HSOCKET hListenSock = INVALID_SOCKET;

void UpdateFileContent(std::string& oFile)
{
	struct stat oFileStat;
	int nRes = stat(oFile.c_str(), &oFileStat);
	if (nRes != 0)
	{
		perror(NULL);
		return;
	}
	int nFileSize = oFileStat.st_size;
	time_t nModTime = oFileStat.st_mtime;

	SCRIPT* poScript = NULL;
	std::unordered_map<std::string, SCRIPT>::iterator iter = goScriptMgr.find(oFile);
	if (iter != goScriptMgr.end())
	{
		if (iter->second.nModTime == oFileStat.st_mtime)
		{
			return;
		}
		poScript = &iter->second;
	}

	FILE* poFile = fopen(oFile.c_str(), "r");
	if (poFile == NULL)
	{
		perror(NULL);
		fclose(poFile);
		return;
	}
	char* pData = (char*)XALLOC(NULL, nFileSize);
	int nReaded = (int)fread(pData, sizeof(char), nFileSize, poFile);
	if (nReaded != nFileSize)
	{
		std::cout << "File size error!" << std::endl;
		fclose(poFile);
		assert(false);
		return;
	}
	if (poScript == NULL)
	{
		SCRIPT oScript;
		goScriptMgr[oFile] = oScript;
		poScript = &goScriptMgr.find(oFile)->second;
	}
	else
	{
		poScript->oData.clear();
	}
	poScript->oData.append(pData, nFileSize);
	poScript->nModTime = nModTime;
	SAFE_DELETE(pData);
	fclose(poFile);
}

void TraverseDir(const std::string& oDir)
{
	DIR *dir;
	struct dirent *ptr;
	if ((dir = opendir(oDir.c_str())) == NULL)
	{
		perror("Open dir error...");
		return;
	}
	//readdir() return next enter point of directory dir
	while ((ptr = readdir(dir)) != NULL)
	{
		if (ptr->d_type == 2
			&& strcmp(ptr->d_name, "..") != 0
			&& strcmp(ptr->d_name, ".") != 0
			&& strcmp(ptr->d_name, "Protocol") != 0)
		{
			std::cout << "[DIR] " << oDir.c_str() << "/" << ptr->d_name << std::endl;
			std::string oSubDir = oDir + "/" + ptr->d_name;
			TraverseDir(oSubDir);
		}
		else if (ptr->d_type == 1)
		{
			std::string oFile= oDir + "/" + ptr->d_name;
			if (strstr(ptr->d_name, ".lua") != NULL)
			{
				std::cout << oFile << std::endl;
				UpdateFileContent(oFile);
			}
		}
	}
	closedir(dir);
}

std::string* SearchScript(std::string oFile, std::string* poFilePath = NULL)
{
	std::unordered_map<std::string, SCRIPT>::iterator iter = goScriptMgr.begin();
	std::unordered_map<std::string, SCRIPT>::iterator iter_end = goScriptMgr.end();
	for (; iter != iter_end; iter++)
	{
		const std::string& oPath= iter->first;
		SCRIPT& oScript = iter->second;
		int nPos = (int)oPath.rfind(oFile);
		if (nPos != std::string::npos)
		{
			if (poFilePath != NULL)
			{
				*poFilePath = oPath;
			}
			return &oScript.oData;
		}
	}
	return NULL;
}

void SplitCmd(std::string oStrCmd, char cDelim, std::vector<std::string>& oCmdVec)
{
	int nLast = 0;
	int nCmdSize = (int)oStrCmd.size();
	for (int i = 0; i < nCmdSize; i++)
	{
		if (oStrCmd[i] == cDelim || i == nCmdSize - 1)
		{
			int nSubSize = i - nLast;
			if (i == nCmdSize - 1)
			{
				nSubSize++;
			}
			if (nSubSize > 0)
			{
				std::string oStr = oStrCmd.substr(nLast, nSubSize);
				oCmdVec.push_back(oStr);
			}
			nLast = i + 1;
		}
	}
}

void ProcessCmd()
{
	static std::vector<std::string> oParamVec;
	if (goCmdVec.size() <= 0)
	{
		return;
	}
	for (int i = (int)goCmdVec.size() - 1; i >= 0; i--)
	{
		oParamVec.clear();
		SplitCmd(goCmdVec[i], ' ', oParamVec);
		if (oParamVec.size() > 0)
		{
			std::string oCmd = oParamVec[0];
			if (oCmd == "test")
			{
				if (oParamVec.size() < 2)
				{
					std::cout << "Example: test test.lua" << std::endl;
				}
				else
				{
					std::string oPath;
					if (SearchScript(oParamVec[1], &oPath) != NULL)
					{
						std::cout << oPath << std::endl;
					}
					else
					{
						std::cout << "File not found!" << std::endl;
					}
				}
			}
			else if (oCmd == "update")
			{
				TraverseDir(oScriptDir);
			}
			else
			{
				std::cout << "Cmd: " << oCmd << " not define" << std::endl;
			}
		}
	}
	goCmdVec.clear();
}

void WorkerThread(void* pParam)
{
	fd_set oReadSet;
	int nClientNum = 0;
	const int nMaxClient = 128;
	HSOCKET tClientSock[nMaxClient];
	memset(tClientSock, 0, sizeof(tClientSock));

	int nMSTimeOut = 100;
	struct timeval tv = { (long)(nMSTimeOut / 1000), (long)(nMSTimeOut % 1000 * 1000) };
	for (;;)
	{
		ProcessCmd();

		FD_ZERO(&oReadSet);
		FD_SET(hListenSock, &oReadSet);
		for (int i = 0; i < nClientNum; i++)
		{
			FD_SET(tClientSock[i], &oReadSet);
		}
		// First param 'nfds' will be ignored in window
		int nRet = ::select(1024, &oReadSet, NULL, NULL, &tv);
		if (nRet > 0)
		{
			if (FD_ISSET(hListenSock, &oReadSet))
			{
				uint32_t uRemoteIP;
				HSOCKET hClient = NetAPI::Accept(hListenSock, &uRemoteIP, NULL);
				if (hClient != INVALID_SOCKET)
				{
					if (nClientNum < nMaxClient)
					{
						tClientSock[nClientNum++] = hClient;
						char sStrIP[128] = { 0 };
						std::cout << "Client connect " << NetAPI::N2P(uRemoteIP, sStrIP, sizeof(sStrIP)) << std::endl;
					}
					else
					{
						std::cout << "Client out of range:" << nClientNum << std::endl;
					}
				}
			}
			for (int i = 0; i < nClientNum;)
			{
				if (FD_ISSET(tClientSock[i], &oReadSet))
				{
					char sModuleName[256] = { 0 };
					int nReaded = ::recv(tClientSock[i], sModuleName, sizeof(sModuleName), 0);
					if (nReaded > 0)
					{

						std::string oPath;
						std::string* poData = SearchScript(sModuleName, &oPath);
						if (poData == NULL)
						{
							int nSize = 0;
							::send(tClientSock[i], (char*)&nSize, sizeof(nSize), 0);
						}
						else
						{
							int nSize = (int)poData->size();
							::send(tClientSock[i], (char*)&nSize, sizeof(nSize), 0);
							::send(tClientSock[i], poData->c_str(), nSize, 0);
						}
						NetAPI::CloseSocket(tClientSock[i]);
						tClientSock[i] = tClientSock[--nClientNum];
					}
				}
				else
				{
					i++;
				}
			}
		}
		else if (nRet == -1)
		{
#ifdef _WIN32
			const char* pErr = Platform::LastErrorStr(GetLastError());
#else
			const char* pErr = strerror(errno);
#endif
			std::cout << pErr << std::endl;
		}
	}

}

int main(int nArg, char *pArgv[])
{
#ifdef _WIN32
	::SetUnhandledExceptionFilter(Platform::MyUnhandledFilter);
#endif

	NetAPI::StartupNetwork();
	TraverseDir(oScriptDir);
	hListenSock = NetAPI::CreateTcpSocket();
	if (!NetAPI::Bind(hListenSock, 0, 64000))
	{
		exit(1);
	}
	if (!NetAPI::Listen(hListenSock))
	{
		exit(2);
	}
	Thread oWorker;
	oWorker.Create(WorkerThread, NULL);

	char sInput[1024];
	for (;;)
	{
		XTime::MSSleep(100);
		std::cout << "Input:";
		std::cin.getline(sInput, sizeof(sInput));
		goCmdVec.push_back(sInput);
	}
};