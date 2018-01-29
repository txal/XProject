#ifndef __PLATFORM_HEADER_H__
#define __PLATFORM_HEADER_H__

#include <time.h>
#include <math.h>
#include <stdio.h>
#include <errno.h>
#include <stdint.h>
#include <string.h>
#include <assert.h>
#include <stdlib.h>
#include <stdarg.h>
#include <signal.h>
#include <string>
#include <sstream>
#include <map>
#include <set>
#include <list>
#include <queue>
#include <vector>
#include <iostream>
#include <unordered_map>
#include "Common/DataStruct/Memory.h"

//在 Win32 配置下，_WIN32 有定义，_WIN64 没有定义。在 x64 配置下，两者都有定义。即在 VC 下，_WIN32 一定有定义。
#ifdef _WIN32

//#include <Ws2tcpip.h>
//#include <WinSock2.h>
#include <windows.h>
#include <process.h>
#include <dbghelp.h>
#include <direct.h>
#include <fcntl.h>
#include <io.h>

#pragma comment(lib, "ws2_32.lib")
#pragma comment(lib, "Dbghelp.lib")
#pragma warning(disable : 4996) 

#define DLL_API __declspec(dllexport)
#define DLL_IMPORT __declspec(dllimport)
#define snprintf _snprintf

typedef SOCKET HSOCKET;
typedef HANDLE THREAD;

#define STDIN_FILENO 0
#define STDOUT_FILENO 1
#define STDERR_FILENO 2

#else

#include <poll.h>
#include <fcntl.h>
#include <signal.h>
#include <unistd.h>
#include <pthread.h>
#include <sys/time.h>
#include <sys/epoll.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/eventfd.h>
#include <sys/stat.h>
#include <arpa/inet.h> // inet_pton & inet_ntop
#include <netinet/in.h> // INADDR_ANY
#include <netinet/tcp.h> // TCP_NODELAY
#include <iconv.h>

#define DLL_API
#define DLL_IMPORT
#define INVALID_SOCKET -1
#define SOCKET_ERROR -1

typedef int HSOCKET;
typedef pthread_t THREAD;
typedef void* HANDLE;

#endif

// 禁止使用拷贝构造函数和 operator= 赋值操作的宏
// 应该类的 private: 中使用
#define DISALLOW_COPY_AND_ASSIGN(TypeName) \
            TypeName(const TypeName&); \
            TypeName& operator=(const TypeName&)

#endif

#define NOTUSED(V) ((void) V);