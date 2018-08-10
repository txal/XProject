#include "Include/Script/LuaWrapper.h"
#include "Include/Network/NetAPI.h"
#include "Common/DataStruct/XMath.h"
#include <sys/stat.h>

extern int snapshot(lua_State *L);

//自定义函数
luaL_Reg CustomFuncList[] =
{
	{ "CustomPrint", LuaWrapper::CustomPrint },
	{ "CustomError", LuaWrapper::CustomError },
	{ "CustomDebug", LuaWrapper::CustomDebug },
	{ "ReloadScript", LuaWrapper::ReloadScript },
	{ "LuaTrace", LuaWrapper::LuaTrace},
	{ "Snapshot", snapshot},
	{ NULL, NULL },
};

LuaWrapper* LuaWrapper::Instance()
{
	static LuaWrapper oSingleton;
	return &oSingleton;
}

LuaWrapper::LuaWrapper()
	: m_oRefMap(1024)
	, m_oScriptMap(1024)
{
	m_pState = NULL;
	m_sScriptServerIP[0] = 0;
	m_uScriptServerPort = 0;
	m_poDebugger = NULL;
	m_nErrFuncRef = -1;
	m_bDebug = true;
	m_bBreaking = false;

}


LuaWrapper::~LuaWrapper()
{
	LuaRefIter iter = m_oRefMap.begin();
	LuaRefIter iter_end = m_oRefMap.end();
	for (; iter != iter_end; iter++)
	{
		luaL_unref(m_pState, LUA_REGISTRYINDEX, iter->second->nRefID);
		SAFE_DELETE(iter->second);
	}
	luaL_unref(m_pState, LUA_REGISTRYINDEX, m_nErrFuncRef);

	LuaScriptIter siter = m_oScriptMap.begin();
	LuaScriptIter siter_end  = m_oScriptMap.end();
	for(; siter != siter_end; siter++)
	{
		SAFE_DELETE(siter->second);
	}	
	lua_close(m_pState);
}

bool LuaWrapper::Init(bool bDebug)
{
	m_bDebug = bDebug;
	m_pState = luaL_newstate();
	luaL_openlibs(m_pState);

	RegLoader();
	RegFnList(CustomFuncList, NULL);

	lua_pushcfunction(m_pState, LuaErrorHandler);
	m_nErrFuncRef = luaL_ref(m_pState, LUA_REGISTRYINDEX);

	FILE* poScriptSrv = fopen("./ScriptServer.txt", "r");
	if (poScriptSrv != NULL)
	{
		if (fgets(m_sScriptServerIP, sizeof(m_sScriptServerIP), poScriptSrv) != NULL)
		{
			int nLen = (int)strlen(m_sScriptServerIP);
			m_sScriptServerIP[nLen - 1] = '\0';
			char sPort[8] = { 0 };
			if (fgets(sPort, sizeof(sPort), poScriptSrv) != NULL)
			{
				m_uScriptServerPort = (uint16_t)atoi(sPort);
			}
		}
		fclose(poScriptSrv);
	}
	return true;
}

void LuaWrapper::AddSearchPath(const char* pPath)
{
	if (pPath == NULL)
	{
		return;
	}
	lua_getglobal(m_pState, "package");
	lua_getfield(m_pState, -1, "path");
	lua_pushstring(m_pState, pPath);
	lua_concat(m_pState, 2);
	lua_setfield(m_pState, -2, "path");
}

LUA_REF* LuaWrapper::RegLuaRef(const char* pName)
{
	lua_getglobal(m_pState, pName);
	if (lua_isnil(m_pState, -1))
	{
		lua_pop(m_pState, 1);
		XLog(LEVEL_ERROR, "Global lua function '%s' not found\n", pName);
		return NULL;
	}
	LuaRefIter iter = m_oRefMap.find(pName);
	LUA_REF* poRef = iter != m_oRefMap.end() ? iter->second : NULL;
	// Remove old ref
	if (poRef != NULL && poRef->nRefID >= 0)
	{
		luaL_unref(m_pState, LUA_REGISTRYINDEX, poRef->nRefID);
		poRef->nRefID = -1;
	}
	else if (poRef == NULL)
	{
		poRef = XNEW(LUA_REF);
		strcpy(poRef->sName, pName);
		m_oRefMap.insert(std::make_pair(pName, poRef));
	}
	poRef->nRefID = luaL_ref(m_pState, LUA_REGISTRYINDEX);
	return poRef;
}

LUA_REF* LuaWrapper::GetLuaRef(const char* pName)
{
	if (pName == NULL)
	{
		return NULL;
	}

	LUA_REF* poRef = NULL;
	LuaRefIter iter = m_oRefMap.find(pName);
	if (iter == m_oRefMap.end())
	{
		poRef = RegLuaRef(pName);
	}
	else
	{
		poRef = iter->second;
	}
	return poRef;
}

void LuaWrapper::RegFnList(luaL_Reg* pFnList, const char* pTable)
{
	if (pTable == NULL)
	{
		lua_pushglobaltable(m_pState);
	}
	else
	{
		lua_getglobal(m_pState, pTable);
		if (lua_isnil(m_pState, -1))
		{
			lua_newtable(m_pState);
			lua_pushvalue(m_pState, -1);
			lua_setglobal(m_pState, pTable);
		}
	}
	for (luaL_Reg *r = pFnList; r->name; r++)
	{
		lua_pushcfunction(m_pState, r->func);
		lua_setfield(m_pState, -2, r->name);
	}
}

bool LuaWrapper::DoFile(const char* pFileName)
{
	lua_getglobal(m_pState, "require");
	lua_pushstring(m_pState, pFileName);
	return PCall(1, 0);
}

bool LuaWrapper::RawDoFile(const char* pFileName)
{
	bool bRes = true;
	if (luaL_dofile(m_pState, pFileName))
	{
		XLog(LEVEL_ERROR, "%s\n", lua_tostring(m_pState, -1));
		lua_pop(m_pState, 1);
		bRes = false;
	}
	lua_settop(m_pState, 0);
	return bRes;
}

bool LuaWrapper::PCall(int nArgs, int nResults)
{
	lua_rawgeti(m_pState, LUA_REGISTRYINDEX, m_nErrFuncRef);
	int nErrFuncIndex = -nArgs - 2;
	lua_insert(m_pState, nErrFuncIndex);
	if (lua_pcall(m_pState, nArgs, nResults, nErrFuncIndex))
	{
		lua_settop(m_pState, 0);
		return false;
	}
	lua_settop(m_pState, nResults);
	return true;
}

bool LuaWrapper::CallLuaRef(int nLuaRef, int nArgs, int nResults)
{
	lua_rawgeti(m_pState, LUA_REGISTRYINDEX, nLuaRef);
	lua_insert(m_pState, -nArgs-1);
	return PCall(nArgs, nResults);
}

bool LuaWrapper::CallLuaRef(const char* psFunc, int nArgs, int nResults)
{
	LUA_REF* poRef = GetLuaRef(psFunc);
	if (poRef == NULL)
	{
		XLog(LEVEL_ERROR, "'%s' ref not found\n", psFunc);
		return false;
	}
	return CallLuaRef(poRef->nRefID, nArgs, nResults);
}

bool LuaWrapper::CallLuaFunc(const char* psTable, const char* psFunc, int nArgs, int nResults)
{
	int nTop = lua_gettop(m_pState);
	if (nTop < nArgs)
	{
		XLog(LEVEL_ERROR, "Args error\n");
		return false;
	}
	if (psTable != NULL)
	{
		lua_getglobal(m_pState, psTable);
	}
	else
	{
		lua_pushglobaltable(m_pState);
	}
	if (!lua_istable(m_pState, -1))
	{
		XLog(LEVEL_ERROR, "Global table '%s' not found\n", psTable);
		return false;
	}
	lua_getfield(m_pState, -1, psFunc);
	if (!lua_isfunction(m_pState, -1))
	{
		XLog(LEVEL_ERROR, "Global lua func '%s' not found\n", psFunc);
		return false;
	}
	lua_insert(m_pState, nTop - nArgs + 1);
	lua_settop(m_pState, nTop + 1);
	return PCall(nArgs, nResults);
}


void LuaWrapper::DumpStack()
{
	XLog(LEVEL_INFO, "Dump stack:\n");
	int nNum = (int)lua_gettop(m_pState);
	for (int i = nNum; i >= 1; i--)
	{
		switch(lua_type(m_pState, i))
		{
			case LUA_TNIL:
			{
				XLog(LEVEL_INFO, "nil\n");
				break;
			}
			case LUA_TBOOLEAN:
			{
				XLog(LEVEL_INFO, lua_toboolean(m_pState, i) ? "true\n" : "false\n");
				break;
			}
			case LUA_TSTRING:
			{
				XLog(LEVEL_INFO, "%s\n", lua_tostring(m_pState, i));
				break;
			}
			case LUA_TTABLE:
			{
				XLog(LEVEL_INFO, "table:0x%0x\n", lua_topointer(m_pState, i));
				break;
			}
			default:
			{
				XLog(LEVEL_INFO, "%s\n", lua_typename(m_pState, lua_type(m_pState, i)));
				break;
			}
		}
	}
}

bool LuaWrapper::IsDebugEnable()
{
	return m_bDebug;
}

LuaDebugger* LuaWrapper::NewDebugger()
{
	if (m_poDebugger != NULL)
	{
		SAFE_DELETE(m_poDebugger);
	}
	m_poDebugger = XNEW(LuaDebugger)(m_pState);
	return m_poDebugger;
}

// Custom lua function
int LuaWrapper::CustomLoader(lua_State* pState)
{
	size_t uLen = 0;
	char* pScriptName = (char*)luaL_checklstring(pState, -1, &uLen);
	LuaWrapper* poWrapper = (LuaWrapper*)lua_topointer(pState, lua_upvalueindex(1));
	if (poWrapper == NULL)
	{
		return luaM_error(pState, "Upvalue 1 not found\n");
	}

	char sFileName[256] = { 0 };
	char sModuleName[256] = { 0 };
	if (strstr(pScriptName, ".lua") == NULL)
	{
		strcpy(sModuleName, pScriptName);
		sprintf(sFileName, "%s.lua", pScriptName);
	}
	else
	{
		strcpy(sFileName, pScriptName);
		memcpy(sModuleName, pScriptName, uLen - 4);
	}
	int nFileSize = 0;
	char* pCont = NULL;
	if (poWrapper->m_uScriptServerPort == 0)
	{
		char sPath[256] = { 0 };
		sprintf(sPath, "Script/%s", sFileName);
		FILE* poFile = fopen(sPath, "r");
		if (poFile == NULL)
		{
			sprintf(sPath, "../Script/%s", sFileName);
			poFile = fopen(sPath, "r");
			if (poFile == NULL)
			{
				sprintf(sPath, "%s", sFileName);
				poFile = fopen(sPath, "r");
				if (poFile == NULL)
				{
					XLog(LEVEL_ERROR, "File not found:%s\n", sPath);
					return 0;
				}
			}
		}
		fseek(poFile, 0, SEEK_END);
		nFileSize = ftell(poFile);
		fseek(poFile, 0, SEEK_SET);
		pCont = (char*)XALLOC(NULL, nFileSize);
		memset(pCont, 0, nFileSize);
		nFileSize = (int)fread(pCont, 1, nFileSize, poFile);
		fclose(poFile);
	}
	else
	{
		// Load script from remote
		HSOCKET hSock = NetAPI::CreateTcpSocket();
		if (!NetAPI::Connect(hSock, poWrapper->m_sScriptServerIP, poWrapper->m_uScriptServerPort))
		{
			XLog(LEVEL_ERROR, "Connot %s:%d fail(%s)\n"
				, poWrapper->m_sScriptServerIP, poWrapper->m_uScriptServerPort, sFileName);
			return 0;
		}
		int nSent = ::send(hSock, sFileName, (int)strlen(sFileName), 0);
		if (nSent <= 0)
		{
			return 0;
		}
		int nReaded = ::recv(hSock, (char*)&nFileSize, sizeof(nFileSize), 0);
		if (nReaded <= 0 || nFileSize <= 0)
		{
			return 0;
		}
		pCont = (char*)XALLOC(NULL, nFileSize);
		memset(pCont, 0, nFileSize);
		nReaded = ::recv(hSock, pCont, nFileSize, 0);
		if (nReaded != nFileSize)
		{
			SAFE_FREE(pCont);
			XLog(LEVEL_ERROR, "Recv file size error!\n");
			return 0;
		}
	}
    LuaScriptIter iter = poWrapper->m_oScriptMap.find(sModuleName);
	SCRIPT* poScript = iter != poWrapper->m_oScriptMap.end() ? iter->second : NULL;
	if (poScript == NULL)
	{
		poScript = XNEW(SCRIPT)(sModuleName);
		poWrapper->m_oScriptMap.insert(std::make_pair(sModuleName, poScript));
	}
	else if (poScript->pCont != NULL)
	{
		SAFE_FREE(poScript->pCont);
	}
	poScript->nSize = nFileSize;
	poScript->pCont = pCont;

	if (luaL_loadbuffer(pState, poScript->pCont, poScript->nSize, poScript->sModuleName))
	{
		return luaM_error(pState, lua_tostring(pState, -1));
	}
	return 1;  // Loaded successfully
}


const char* LuaWrapper::MakePrintMsg(lua_State* pState)
{
#ifdef _DEBUG
	luaL_where(pState, 1);
	const char* pWhere = lua_tostring(pState, -1);
	lua_pop(pState, 1);
	NOTUSED(pWhere);
#endif

	static const int nMaxLogLen = 1024;
	static char sBuf[nMaxLogLen];
	memset(sBuf, 0, sizeof(sBuf));
	char* pPos = sBuf;
	char* pEnd = sBuf + nMaxLogLen - 1;

	int nTop = lua_gettop(pState);
	lua_getglobal(pState, "tostring");
	for (int i = 1; i <= nTop; i++)
	{
		if (pPos >= pEnd)
		{
			break;
		}
		const char *pStr;
		size_t nLen;
		lua_pushvalue(pState, -1);
		lua_pushvalue(pState, i);
		lua_call(pState, 1, 1);
		pStr = lua_tolstring(pState, -1, &nLen);
		if (pStr == NULL)
		{
			const char* psErr = LUA_QL("tostring") " must return a string to " LUA_QL("print");
			int nCopy = XMath::Min((int)(pEnd - pPos), (int)strlen(psErr));
			memcpy(pPos, psErr, nCopy);
			break;
		}
		if (i > 1)
		{
			int nCopy = XMath::Min((int)(pEnd - pPos), 1);
			memcpy(pPos, "\t", nCopy);
			pPos += nCopy;
			if (pPos >= pEnd)
			{
				break;
			}
		}
		int nCopy = XMath::Min((int)(pEnd - pPos), (int)nLen);
		memcpy(pPos, pStr, nCopy);
		pPos += nCopy;
		if (pPos >= pEnd)
		{
			break;
		}
		lua_pop(pState, 1);
	}
	return sBuf;
}

int LuaWrapper::CustomPrint(lua_State* pState)
{
#ifdef _DEBUG
	const char* psBuf = MakePrintMsg(pState);
	XLog(LEVEL_INFO, "%s\n", psBuf);
#endif
	return 0;
}

int LuaWrapper::LuaTrace(lua_State* pState)
{
	const char* psBuf = MakePrintMsg(pState);
	XLog(LEVEL_INFO, "%s\n", psBuf);
	return 0;
}

int LuaWrapper::CustomDebug(lua_State* pState)
{
	const char* psBuf = MakePrintMsg(pState);
	XLog(LEVEL_DEBUG, "%s\n", psBuf);
	return 0;
}

int LuaWrapper::CustomError(lua_State* pState)
{
	lua_settop(pState, 1);
	const char* pMsg = "";
	if (lua_isstring(pState, 1))
	{
		pMsg = lua_tostring(pState, 1);
	}
	luaL_traceback(pState, pState, pMsg, 1);
	return lua_error(pState);
}

int LuaWrapper::luaM_error(lua_State* pState, const char* pFmt, ...)
{
	va_list Argp;
	va_start(Argp, pFmt);
	lua_pushvfstring(pState, pFmt, Argp);
	va_end(Argp);
	luaL_traceback(pState, pState, "", 1);
	lua_concat(pState, 2);
	return lua_error(pState);
}

void LuaWrapper::UpdateLuaRefs()
{
	LuaRefIter iter = m_oRefMap.begin();
	LuaRefIter iter_end = m_oRefMap.end();
	for (; iter != iter_end; iter++)
	{
		RegLuaRef(iter->second->sName);
	}
}

bool LuaWrapper::RegLoader()
{
	lua_pushlightuserdata(m_pState, this);
	lua_pushcclosure(m_pState, CustomLoader, 1);
	int nLoaderIndex = lua_gettop(m_pState);
	lua_getfield(m_pState, LUA_REGISTRYINDEX, "_LOADED");
	lua_getfield(m_pState, -1, "package");
	lua_getfield(m_pState, -1, "searchers");
	int nSearcherIndex = lua_gettop(m_pState);
	int nLen = (int)luaL_len(m_pState, -1) + 1;
	for(int i = nLen; i > 1; i--)
	{
		lua_rawgeti(m_pState, nSearcherIndex, i - 1);
		lua_rawseti(m_pState, nSearcherIndex, i);
	}
	lua_pushvalue(m_pState, nLoaderIndex);
	lua_rawseti(m_pState, nSearcherIndex, 1);
	return true;
}

int LuaWrapper::ReloadScript(lua_State* pState)
{
	const char* psScriptName = luaL_checkstring(pState, 1);
	bool bRes = LuaWrapper::Instance()->DoFile(psScriptName);
	LuaWrapper::Instance()->UpdateLuaRefs();
	lua_pushboolean(pState, bRes);
	return 1;
}

void LuaWrapper::ClearLoadedModule(const char* psScriptName)
{
	if (psScriptName == NULL)
	{
		return;
	}
    int nLen = (int)strlen(psScriptName);
	char sModuleName[256] = { 0 };
	if (strstr(psScriptName, ".lua") == NULL)
	{
		strcpy(sModuleName, psScriptName);
	}
	else
	{
		memcpy(sModuleName, psScriptName, nLen - 4);
	}
	lua_settop(m_pState, 0);
	lua_getfield(m_pState, LUA_REGISTRYINDEX, "_LOADED");
	lua_pushnil(m_pState);
	lua_setfield(m_pState, 1, sModuleName);
}

SCRIPT* LuaWrapper::FindScript(const char* psScriptName)
{
	if (psScriptName == NULL)
	{
		return NULL;
	}
    int nLen = (int)strlen(psScriptName);
	char sModuleName[256] = { 0 };
	if (strstr(psScriptName, ".lua") == NULL)
	{
		strcpy(sModuleName, psScriptName);
	}
	else
	{
		memcpy(sModuleName, psScriptName, nLen - 4);
	}
	LuaScriptIter iter = m_oScriptMap.find(sModuleName);
	if (iter != m_oScriptMap.end())
	{
		return iter->second;
	}
	return NULL;
}