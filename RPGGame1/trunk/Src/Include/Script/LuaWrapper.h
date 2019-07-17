#ifndef __LUA_WRAPPER_H__
#define __LUA_WRAPPER_H__

#include "Include/Logger/Logger.h"
#include "Include/Script/lunar.h"
#include "Include/Script/LuaDebugger.h"
#include "Common/DataStruct/XThread.h"


struct LUA_REF
{
	char sName[256];
	int nRefID;

	LUA_REF()
	{
		nRefID = -1;
		sName[0] = '\0';
	}
};

struct SCRIPT
{
	char sModuleName[256];	
	char* pCont;
	int nSize;

	SCRIPT(const char* pModuleName)
	{ 
		strcpy(sModuleName, pModuleName);
		pCont = NULL; 
		nSize = 0;
	}
	~SCRIPT()
	{ 
		SAFE_FREE(pCont);
	}
};

class LuaWrapper
{
public:
	typedef std::unordered_map<std::string, LUA_REF*> LuaRefMap;
	typedef LuaRefMap::iterator LuaRefIter;

	typedef std::unordered_map<std::string, SCRIPT*> LuaScriptMap;
	typedef LuaScriptMap::iterator LuaScriptIter;

public:
	static LuaWrapper* Instance();
	static void Release();
	~LuaWrapper();

	bool Init(bool bDebug);
	lua_State* GetLuaState() { return m_pState; }
	void AddSearchPath(const char* pPath);
	LUA_REF* RegLuaRef(const char* pName);
	LUA_REF* GetLuaRef(const char* pName);
	void RegFnList(luaL_Reg* pFnList, const char* pTable);

public:
	void DumpStack();
	bool DoFile(const char* pFlieName);
	bool RawDoFile(const char* pFileName);
	bool PCall(int nArgs, int nResults);
	bool CallLuaRef(int nLuaRef, int nArgs = 0, int nResults = 0);
	bool CallLuaRef(const char* psFunc, int nArgs = 0, int nResults = 0);
	bool CallLuaFunc(const char* psTable, const char* psFunc, int nArgs = 0, int nResults = 0);	//直接调用不产生Ref
	template<typename RT,typename PT>
	RT FastCallLuaRef(const char* psFunc, const char sReturnType = 0, const char* psParamList = NULL, ...);

	///////debug///////
	bool IsDebugEnable();
	LuaDebugger* NewDebugger();
	LuaDebugger* GetDebugger() { return m_poDebugger; }
	SCRIPT* FindScript(const char* psScriptName);
	void SetEndlessLoop(int nFlag) { gnEndlessLoopFlag = nFlag; }
	void SetBreaking(bool bBreak) { m_bBreaking = bBreak; }
	bool IsBreaking() { return m_bBreaking;}

public:

public:
	// Custom loader
	static int CustomLoader(lua_State* pState);
	// Custom lua print
	static int CustomPrint(lua_State* pState);	//只有在DEBUG模式下有效
	// Lua trace
	static int LuaTrace(lua_State* pState);		//DEBUG/RELEASE都有效
	// Debug out put
	static int CustomDebug(lua_State* pState);
	// Custom lua error
	static int CustomError(lua_State* pState);
	// Custom c/c++ luaL_error
	static int luaM_error(lua_State* pState, const char *pFmt, ...);
	// Reload script file
	static int ReloadScript(lua_State* pState);
	// Make lua print msg
	static const char* MakePrintMsg(lua_State* pState);
  
private:
	// Local memory allocator
	static void *CustomAlloc(void* pUD, void* pPtr, size_t nOldSize, size_t nNewSize)
	{
		return NULL;
		//return alloc::reallocate(ptr, osize, nsize);
	}
    bool RegLoader();
	void UpdateLuaRefs();
	void ClearLoadedModule(const char* psScriptName);

private:
	lua_State* m_pState;

	// Ref 
	LuaRefMap m_oRefMap;
	int m_nErrFuncRef;

	// Script files
	LuaScriptMap m_oScriptMap;

	// Script server
	char m_sScriptServerIP[128];
	uint16_t m_uScriptServerPort;

	// Debug
	LuaDebugger* m_poDebugger;
	bool m_bDebug;
	bool m_bBreaking;
	
	LuaWrapper();
	DISALLOW_COPY_AND_ASSIGN(LuaWrapper);
};

#define REG_CLASS(ClassName, bDel, fnPreDelete)  \
	{\
		lua_State* pState = LuaWrapper::Instance()->GetLuaState(); \
		Lunar<ClassName>::Register(pState, bDel, fnPreDelete); \
	}


template<typename RT,typename PT>
RT LuaWrapper::FastCallLuaRef(const char* psFunc, const char cReturnType, const char* psFormat, ...)
{
	LUA_REF* poRef = GetLuaRef(psFunc);
	if (poRef == NULL)
	{
		return RT();
	}

	int nArgCount = 0;
	if (psFormat != NULL)
	{
		va_list vl;
		va_start(vl, psFormat);
		const char* pIndex = psFormat;
		while (*pIndex != '\0')
		{
			switch (*pIndex++)
			{
				case 'b':
				{
					lua_pushboolean(m_pState, va_arg(vl, int32_t));
				}break;
				case 'c':
				case 'C':
				case 'w':
				case 'W':
				case 'i':
				{
					lua_pushinteger(m_pState, va_arg(vl, int32_t));
				}break;
				case 'I':
				{
					lua_pushinteger(m_pState, va_arg(vl, uint32_t));
				}break;
				case 'q':
				{
					lua_pushinteger(m_pState, va_arg(vl, int64_t));
				}break;
				case 'f':
				case 'd':
				{
					lua_pushnumber(m_pState, va_arg(vl, double));
				}break;
				case 's':
				{
					lua_pushstring(m_pState, va_arg(vl, const char*));
				}break;
				case 'u':
				{
					Lunar<PT>::push(m_pState, (PT*)va_arg(vl, void*));
				}break;
				default:
				{
				   XLog(LEVEL_ERROR, "FastCallLuaFunc format type not support:%s\n", psFormat);
				   va_end(vl);
				   return RT();
				}break;
			}
			++nArgCount;
		}
		va_end(vl);
	}
	if (!CallLuaRef(poRef->nRefID, nArgCount, 1) || cReturnType == 0)
	{
		return RT();
	}
	switch (cReturnType)
	{
		case 'i':
		{
			int32_t nRes = (int32_t)luaL_checkinteger(m_pState, 1);
			return (RT)nRes;
		}
		case 'q':
		{
			int64_t nRes = (int64_t)luaL_checkinteger(m_pState, 1);
			return (RT)nRes;
		}
		case 'd':
		{
			double dRes = (double)luaL_checknumber(m_pState, 1);
			return (RT)dRes;
		}
		case 's':
		{
			const char* sRes = (const char*)luaL_checkstring(m_pState, 1);
			return (RT)sRes;
		}
		default:
		{
		   XLog(LEVEL_ERROR, "FastCallLuaFunc return type not support:%c\n", cReturnType);
		}
	}
	return RT();
}

#endif
