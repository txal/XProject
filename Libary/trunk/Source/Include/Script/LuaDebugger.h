#ifndef __LUA_DEBUGGER_H__
#define __LUA_DEBUGGER_H__

#include "Common/Platform.h"
#include "Include/Script/lunar.h"

int LuaErrorHandler(lua_State* pState);
int LuaDebugBreak(lua_State* pState);

class BreakPoint
{
public:
    char*		m_szFileName;
    uint32_t	m_uLineNum;

    BreakPoint(const char* szFileName,uint32_t uLineNum);
    bool operator<(const BreakPoint& ano)const;
    bool operator==(const BreakPoint& ano)const;
    void Store();
    void Clear();

};

class LuaDebugger
{

public:

    LuaDebugger(lua_State* pLuaState);
    ~LuaDebugger();

    bool Debug();
    void SetStepOut();

private:
    bool PrintLine( lua_State *pState, uint32_t uLevel, int32_t nLine, bool bIsCurLine );
    bool HitBreakPoint(lua_State* pState,lua_Debug* pDebug)const;
    bool HaveBreakPoint()const;

    const char* ReadWord(bool bNewLine=false);

    static void HookProc( lua_State *pState, lua_Debug* pDebug );		// 当脚本执行中行跳转时将会调用此函数

    void LineHook( lua_State *pState,lua_Debug* pDebug );

    void SetStepNext();
    void SetStepIn();

private:
    lua_State*  m_pState;
    bool        m_bInCoroutine;
    int32_t       m_nRunningStackLevel;		//当前调试器执行的堆栈深度
    int32_t       m_nBreakStackLevel;		//断点的堆栈深度
    std::string	m_sLastVarName;
    char*       m_pBuf;
    char        m_szBuffer[1024];

    typedef std::set<BreakPoint> BreakPointSet_t;
    BreakPointSet_t	m_setBreakPoint;
};


void RegLuaDebugger(const char *psTable);

#endif