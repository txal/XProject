#ifndef __HTTP_LUA_H__
#define __HTTP_LUA_H__

#include "HttpClient.h"
#include "HttpServer.h"

extern HttpClient goHttpClient;
extern HttpServer goHttpServer;

void RegHttpLua(const char* psTable);
void ProcessHttpMessage();

#endif