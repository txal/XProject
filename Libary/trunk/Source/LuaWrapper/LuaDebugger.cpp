#include "Include/Logger/Logger.h"
#include "Include/Script/LuaDebugger.h"
#include "Include/Script/LuaWrapper.h"
#ifdef __linux
#include <readline/readline.h>
#include <readline/history.h>
#endif

using namespace std;

static int GetCurLine(lua_State *pState, uint32_t uLevel )
{
    lua_Debug ld;
    lua_getstack ( pState, uLevel, &ld );
    lua_getinfo ( pState, "l", &ld );
    return ld.currentline;
}

static uint32_t GetRunStackDepth(lua_State* pState)
{
    lua_Debug ld;
    int32_t uDepth=0;
    for(;lua_getstack ( pState, uDepth, &ld );++uDepth);
    return uDepth;
}

static std::string GetFileNameFromPathName(const char* szPathName)
{
    std::string sFileName=szPathName;
    sFileName.replace(sFileName.begin(),sFileName.end(),'\\','/');
    int32_t nPos= static_cast<int32_t>( sFileName.find_last_of('/') );
    if(nPos != -1)
        sFileName.erase(0,nPos+1);
    return sFileName;
}

void Print_lua( lua_State *pL, const std::list<std::string>& listField )
{
    lua_getglobal( pL, "gfDebugPrint" );
    lua_insert( pL, -2 );
    for(std::list<std::string>::const_iterator it = listField.begin(); it != listField.end(); it++ )
    {
        const char* szStr = it->c_str();
        if( szStr[0] >= '0' && szStr[0] <= '9' )
            lua_pushnumber( pL, atof( szStr ) );
        else
            lua_pushstring( pL, szStr );
    }
    lua_pcall( pL, 1 + (int32_t)listField.size(), 0, 0 );
}

static bool PrintFrame( lua_State *pState, int32_t uLevel )
{
    lua_Debug ld;

    if(!lua_getstack ( pState, uLevel, &ld ))
    {
        return false;
    }

    lua_getinfo ( pState, "n", &ld );
    lua_getinfo ( pState, "S", &ld );
    lua_getinfo ( pState, "l", &ld );

	XLog(LEVEL_DEBUG,"#%d  ", uLevel);

    if(ld.name)
    {
		XLog(LEVEL_DEBUG,"%s", ld.name);
    }
    else
    {
		XLog(LEVEL_DEBUG,"(trunk)");
    }

	XLog(LEVEL_DEBUG," ");

	XLog(LEVEL_DEBUG,"%s", ld.source);

    //if(ld.source[0]=='@')
    //{
	//	XLog(LEVEL_DEBUG,":%d", ld.currentline);
    //}
	XLog(LEVEL_DEBUG,":%d", ld.currentline);

	XLog(LEVEL_DEBUG,"\n");

    return true;
}

//文件大小
static int GetFileSize(FILE* poFile)
{
	fseek(poFile, 0, SEEK_END);
	int nFileSize = ftell(poFile);
	fseek(poFile, 0, SEEK_SET);
	return nFileSize;
}

//-----------------------------------------------------
// 显示脚本某一行
//-----------------------------------------------------
static bool ShowLine( const char* psFilePathName, int line, bool bIsCurLine, bool bIsBreakLine )
{
	std::string oFilePathName = psFilePathName;
	oFilePathName += ".lua";
	FILE* poFile = fopen(oFilePathName.c_str(), "rb");
	if (poFile == NULL)
	{
		std::string oTmpPath = "../Script/" + oFilePathName;
		poFile = fopen(oTmpPath.c_str(), "rb");
		if (poFile == NULL)
		{
			oTmpPath = "./Script/" + oFilePathName;
			poFile = fopen(oTmpPath.c_str(), "rb");
			if (poFile == NULL)
			{
				XLog(LEVEL_DEBUG, "file open fail. file=%s\n", oFilePathName.c_str());
				return false;
			}
		}
	}
	int nFileSize = GetFileSize(poFile);
	char* pCont = (char*)XALLOC(NULL, nFileSize+1);
	if (pCont == NULL)
	{
        XLog(LEVEL_DEBUG, "Memory out!\n");
		return false;
	}
	pCont[nFileSize] = 0;
	int nReadSize = (int)fread(pCont, 1, nFileSize, poFile);
	fclose(poFile);

    if(nReadSize <= 0)
    {
        XLog(LEVEL_DEBUG, "Source not available.\n" );
		SAFE_FREE(pCont);
        return false;
    }
    else
    {
		int c = pCont[0];
        if ( c == '#' || c == LUA_SIGNATURE[0] ) 
        {
			XLog(LEVEL_DEBUG,"%s\t%d(can not support binary file)\n", psFilePathName, line);
        }
        else
        {
            char* pCur = pCont;
            for( int i = 0; i < line - 1; pCur++ )
            {
                if( *pCur == 0 )
                {
					std::string sFileName = GetFileNameFromPathName(psFilePathName);
					XLog(LEVEL_DEBUG,"Line number %d out of range; %s has %d lines.\n", i + 2, sFileName.c_str(), i + 1);
					SAFE_FREE(pCont);
                    return false;
                }
                if( *pCur == '\n' )
                {
                    i++;
                }
            }

            for( int i = 0; pCur[i]; i++ )
            {
                if( pCur[i] == '\r' || pCur[i] == '\n' )
                {
                    pCur[i] = 0;
                    break;
                }
            }

			XLog(LEVEL_DEBUG,"%d", line);
			XLog(LEVEL_DEBUG," ");

			if (bIsBreakLine)
			{
				XLog(LEVEL_DEBUG, "B");
			}
			else
			{
				XLog(LEVEL_DEBUG, " ");
			}
			if (bIsCurLine)
			{
				XLog(LEVEL_DEBUG, ">>");
			}
			XLog(LEVEL_DEBUG,"\t%s\n", pCur);
        }
    }
	SAFE_FREE(pCont);
    return true;
}

int LuaErrorHandler( lua_State* pState )
{
    if( LuaWrapper::Instance()->IsDebugEnable() && !LuaWrapper::Instance()->IsBreaking())
    {
		XLog(LEVEL_DEBUG,"%s\n", lua_tostring( pState, -1));
	    lua_pop( pState, 1);

		LuaWrapper::Instance()->SetBreaking(true);
	    //重新创建一个调试器
	    LuaWrapper::Instance()->NewDebugger()->Debug();
    }
	else
	{
		luaL_traceback(pState, pState, "", 1);
		lua_concat(pState, 2);
		XLog(LEVEL_ERROR,"[LUA ERROR]:%s\n", lua_tostring( pState, -1));
	}
	LuaWrapper::Instance()->SetBreaking(false);
    return 0;
}

int LuaDebugBreak( lua_State* pState )
{
	if (LuaWrapper::Instance()->IsDebugEnable() && !LuaWrapper::Instance()->IsBreaking())
	{
		LuaWrapper::Instance()->SetBreaking(true);
	    LuaWrapper::Instance()->NewDebugger()->Debug();
	}
	LuaWrapper::Instance()->SetBreaking(false);
    return 0;
}


LuaDebugger::LuaDebugger( lua_State* pLuaState )
{
	m_pState = pLuaState;
    m_bInCoroutine = false;
    m_nRunningStackLevel = -1;
    m_nBreakStackLevel = -1;
    m_pBuf = NULL;
    memset(m_szBuffer, 0, sizeof(m_szBuffer));
}

LuaDebugger::~LuaDebugger()
{

}

bool LuaDebugger::Debug()
{
    const char* szBuf;
    bool bAtFileEnd=false;
    int nCurLevel = 0;
    int nCurLine = GetCurLine( m_pState,nCurLevel );

    PrintFrame(m_pState,nCurLevel);
    PrintLine(m_pState,nCurLevel,nCurLine,true);

    for(;;)
    {
        szBuf = ReadWord(true);
        if(!szBuf)
            return false;

        if( !strcmp( szBuf, "help") )
        {
            const char* szHelp=
                "continue/c                        继续执行\n"
                "next/n                            执行下一行\n"
                "in/i                              跳进\n"
                "out/o                             跳出\n"
                "list/l                            列出附近几行代码\n"
                "backtrace/bt                      列出调用堆栈\n"
                "frame/f n                         转到第n层堆栈\n"
                "print/p v                         打印v的值\n"
                "load/lo file                      载入或重新载入并执行指定文件\n"
                "break file:line                   设置断点\n"
                "del n                             取消断点\n"
                "breakpoints/bps                   显示所有的断点\n"
                "ldb                               进入lua自己的debug模式\n"
                "help                              打印帮助\n"
                ;
            XLog(LEVEL_DEBUG,"%s", szHelp);
        }
        else if( !strcmp( szBuf, "quit" ) || !strcmp( szBuf, "exit" ) || !strcmp( szBuf, "q" ) )
        {
            exit(0);
        }
        else if( !strcmp( szBuf, "continue" ) || !strcmp( szBuf, "c" ) )
        {
            if(HaveBreakPoint())
            {
                lua_sethook( m_pState, &LuaDebugger::HookProc, LUA_MASKCALL | LUA_MASKRET | LUA_MASKLINE, 0 );
            }
            break;
        }
        else if( !strcmp( szBuf, "ldb" ) )
        {
            if(luaL_dostring( m_pState, "debug.debug()" ))
            {
				XLog(LEVEL_DEBUG,"%s\n", lua_tostring(m_pState, -1));
                lua_pop( m_pState, 1);
            }
        }
        else if( !strcmp( szBuf, "del" ) )
        {
            szBuf = ReadWord();		//获取del后面的参数

            int32_t nBreakPointNum = 0;

            if( szBuf && isdigit( *szBuf ) )
            {
                //提供了当前文件的断点行号
                nBreakPointNum=atoi(szBuf);
            }
            else
            {
				XLog(LEVEL_DEBUG,"Please supply breakpoint index.\n");
            }

            BreakPointSet_t::iterator it=m_setBreakPoint.begin();

            int32_t i = 1;
            for(;i<nBreakPointNum && it!=m_setBreakPoint.end();++i,++it);

            if(i==nBreakPointNum && it!=m_setBreakPoint.end())
            {
                const_cast<BreakPoint*>(&*it)->Clear();
                m_setBreakPoint.erase(it);
            }
        }
        else if( !strcmp( szBuf, "break" ) )
        {
            szBuf = ReadWord();	//获取break后面的参数

            int32_t nBreakLine=nCurLine;
            const char* szSource=NULL;
            lua_Debug ld;

            if(szBuf)
            {
                if(isdigit(*szBuf))
                {
                    //提供了当前文件的断点行号
                    nBreakLine=atoi(szBuf);
                    lua_getstack( m_pState, nCurLevel, &ld );
                    lua_getinfo( m_pState, "S", &ld );
                    szSource=ld.source;
                }
                else
                {
                    //提供了断点的文件和行号
                    char* pColon =(char*)strchr(szBuf,':');
                    if(!pColon)
                    {
						XLog(LEVEL_DEBUG,"Please supply filename and linenumber.\n");
                        continue;
                    }
                    else if( !isdigit(*(pColon+1)) )
                    {
						XLog(LEVEL_DEBUG,"Please supply linenumber after filename.\n");
                        continue;
                    }
                    *pColon=0;
                    szSource=szBuf;
                    nBreakLine=atoi(pColon+1);
                }
            }
            else
            {
                lua_getstack( m_pState, nCurLevel, &ld );
                lua_getinfo( m_pState, "S", &ld );
                szSource=ld.source;
            }

            std::pair<BreakPointSet_t::iterator,bool> p=
                m_setBreakPoint.insert( BreakPoint(szSource,nBreakLine) );
            if(p.second)
                const_cast<BreakPoint*>(&*p.first)->Store();
        }
        else if( !strcmp( szBuf, "breakpoints" ) || !strcmp( szBuf, "bps") )
        {
            int32_t nNum=1;
            for(BreakPointSet_t::iterator it=m_setBreakPoint.begin();it!=m_setBreakPoint.end();++it,++nNum)
				XLog(LEVEL_DEBUG,"%d\t%s:%d\n", nNum, it->m_szFileName, it->m_uLineNum);
        }
        else if( !strcmp( szBuf, "load" ) || !strcmp( szBuf, "lo") )
        {
            szBuf = ReadWord();
            if(!szBuf)
            {
                lua_Debug ld;
                lua_getstack ( m_pState, nCurLevel, &ld );
                lua_getinfo ( m_pState, "S", &ld );

                if(*ld.source!='@')
                {
					XLog(LEVEL_DEBUG,"Can only load lua file.\n");
                    continue;
                }

                szBuf=(ld.source+1);						
            }
            if(luaL_dofile( m_pState, szBuf ))
            {
				XLog(LEVEL_DEBUG,"%s\n", lua_tostring(m_pState, -1));
                lua_pop( m_pState, 1);
            }
        }
        else if( !strcmp( szBuf, "next" ) || !strcmp( szBuf, "n" ) )
        {
            SetStepNext();
            break;
        }
        else if( !strcmp( szBuf, "nl" ) )
        {
            SetStepNext();

            szBuf = ReadWord();

            int nLineCount=15;			//一次显示代码的行数

            if(szBuf)
            {
                if(isdigit(*szBuf))
                {
                    nCurLine=atoi(szBuf);
                }
                else
                {
                    if(bAtFileEnd)
                    {
                        bAtFileEnd=false;
                        nCurLine-=nLineCount;
                    }
                    else
                    {
                        nCurLine-=nLineCount*2;
                    }

                    if(nCurLine<=nLineCount/2)
                        nCurLine=nLineCount/2;
                }
            }

            int nShowBeginLine=nCurLine-nLineCount/2;	//显示代码的起始位置
            int nShowCounter=0;

            for( nShowCounter = 0; nShowCounter < nLineCount; nShowCounter++ )
            {
                int nShowLine=nShowBeginLine+nShowCounter;
                if(nShowLine>0)
                {
                    if(!PrintLine( m_pState,nCurLevel,nShowLine,nShowLine==GetCurLine(m_pState,nCurLevel)))
                    {
                        bAtFileEnd=true;
                        break;
                    }
                }
            }
            nCurLine+=nShowCounter;

            break;
        }
        else if( !strcmp( szBuf, "in" ) || !strcmp( szBuf, "i" ) )
        {
            SetStepIn();
            break;
        }
        else if( !strcmp( szBuf, "out" ) || !strcmp( szBuf, "o" ) )
        {
            SetStepOut();
            break;
        }
        else if( !strcmp( szBuf, "list" ) || !strcmp( szBuf, "l" ) )
        {
            szBuf = ReadWord();

            int nLineCount=15;			//一次显示代码的行数

            if(szBuf)
            {
                if(isdigit(*szBuf))
                {
                    nCurLine=atoi(szBuf);
                }
                else
                {
                    if(bAtFileEnd)
                    {
                        bAtFileEnd=false;
                        nCurLine-=nLineCount;
                    }
                    else
                    {
                        nCurLine-=nLineCount*2;
                    }

                    if(nCurLine<=nLineCount/2)
                        nCurLine=nLineCount/2;
                }
            }

            int nShowBeginLine=nCurLine-nLineCount/2;	//显示代码的起始位置
            int nShowCounter=0;

            for( nShowCounter = 0; nShowCounter < nLineCount; nShowCounter++ )
            {
                int nShowLine=nShowBeginLine+nShowCounter;
                if(nShowLine>0)
                {
                    if(!PrintLine( m_pState,nCurLevel,nShowLine,nShowLine==GetCurLine(m_pState,nCurLevel)))
                    {
                        bAtFileEnd=true;
                        break;
                    }
                }
            }
            nCurLine+=nShowCounter;
        }
        else if( !strcmp( szBuf, "backtrace" ) || !strcmp( szBuf, "bt" ) )
        {
            for( int i = 0; PrintFrame( m_pState,i); i++ );
        }
        else if( !strcmp( szBuf, "frame" ) || !strcmp( szBuf, "f" ) )
        {
            szBuf = ReadWord();
            bool bValidStackNumber=true;

            if(szBuf)
            {
                int nLevel = nCurLevel;

                if(isdigit(*szBuf))
                {
                    nLevel=atoi( szBuf );

                    lua_Debug ld;
                    if( lua_getstack ( m_pState, nLevel, &ld ) )
                    {
                        nCurLevel = nLevel;
                        nCurLine = GetCurLine( m_pState, nCurLevel );
                        bAtFileEnd=false;
                    }
                    else
                        bValidStackNumber=false;
                }
                else
                    bValidStackNumber=false;
            }
            else
            {
                nCurLine = GetCurLine( m_pState, nCurLevel );
            }
            if(!bValidStackNumber)
            {
				XLog(LEVEL_DEBUG,"Invalid stack number.\n");
                continue;
            }
            PrintFrame( m_pState,nCurLevel );
            PrintLine( m_pState, nCurLevel,nCurLine,true);
        }
        else if( !strcmp( szBuf, "print" ) || !strcmp( szBuf, "p" ) )
        {
            szBuf = ReadWord();

            std::string sVarName;

            if(!szBuf )
            {
                if(m_sLastVarName.empty())
                {
					XLog(LEVEL_DEBUG,"The history is empty.\n");
                    continue;
                }
                sVarName=m_sLastVarName;
            }
            else
            {
                sVarName=szBuf;
            }

            lua_Debug _ar;
            if( lua_getstack ( m_pState, nCurLevel, &_ar ) )
            {					
                std::list<std::string> listField;
                std::vector<char> szTemp( sVarName.size() + 1, 0 );
                memcpy( &szTemp[0], sVarName.c_str(), sVarName.size() );
                szBuf = &szTemp[0];
                for( int32_t i = 0; szTemp[i]; i++ )
                {
                    if( szTemp[i] == '.' )
                    {
                        szTemp[i] = 0;
                        listField.push_back( szBuf );
                        szBuf = &szTemp[i+1];
                    }
                }
                listField.push_back( szBuf );
                std::string sFirstName = *listField.begin();
                listField.erase( listField.begin() );

                int n = 1;
                bool bFound = false;
                const char* name = NULL;
                while( !bFound && ( name = lua_getlocal( m_pState, &_ar, n++ ) ) != NULL ) 
                {
                    bFound = sFirstName == name; //第1个找到的局部变量,如果后面声明了同名变量,打印的也是第1个
					if (bFound)
                        Print_lua( m_pState, listField );
                    else
                        lua_pop( m_pState, 1 ); 
                }

                n = 1;
                lua_getinfo( m_pState, "f", &_ar );
                while( !bFound && ( name = lua_getupvalue( m_pState, -1, n++ ) ) != NULL ) 
                {
                    bFound = sFirstName == name;
                    if( bFound )
                        Print_lua( m_pState, listField );
                    else
                        lua_pop( m_pState, 1 ); 
                }

                if( !bFound )
                {
                    lua_getglobal( m_pState, sFirstName.c_str() );
                    if( ( bFound = lua_type( m_pState, -1 ) != LUA_TNIL ) )
                        Print_lua( m_pState, listField );
                    else
                        lua_pop( m_pState, 1 ); 
                }

                if( !bFound )
                {
                    std::string strExe = "gfDebugPrint(" + sVarName + ")";
                    luaL_dostring( m_pState, strExe.c_str() );
                }
            }
            else
				XLog(LEVEL_DEBUG,"Invalid stack number!\n");

            m_sLastVarName=sVarName;
        }
        else if( strlen ( szBuf) !=0 )
        {
			XLog(LEVEL_DEBUG,"Invalid command!\n");
        }
    }

    return true;
}

void LuaDebugger::SetStepOut()
{
    lua_sethook( m_pState, &LuaDebugger::HookProc, LUA_MASKCALL | LUA_MASKRET | (HaveBreakPoint()?LUA_MASKLINE:0), 0 );
    m_nRunningStackLevel = GetRunStackDepth(m_pState);
    m_nBreakStackLevel = m_nRunningStackLevel-1;	//堆栈级别必须比当前执行深度小1
}

bool LuaDebugger::PrintLine( lua_State *pState, uint32_t uLevel, int32_t nLine, bool bIsCurLine )
{
    if(nLine<0)
    {
		XLog(LEVEL_DEBUG,"Source not available.\n");
        return false;
    }

    lua_Debug ld;
    lua_getstack ( pState, uLevel, &ld );
    lua_getinfo ( pState, "S", &ld );


    bool bIsBreakLine=m_setBreakPoint.find( BreakPoint(ld.source,nLine) )!=m_setBreakPoint.end();		

    return ShowLine(ld.source, nLine, bIsCurLine, bIsBreakLine );
}

bool LuaDebugger::HitBreakPoint( lua_State* pState,lua_Debug* pDebug ) const
{
    if(m_setBreakPoint.empty())
        return false;

    lua_getinfo ( pState, "S", pDebug );
    lua_getinfo ( pState, "l", pDebug );
    if( m_setBreakPoint.find( BreakPoint(pDebug->source,pDebug->currentline) )!=m_setBreakPoint.end() )
        return true;
    return false;
}

bool LuaDebugger::HaveBreakPoint() const
{
    return !m_setBreakPoint.empty();
}

const char* LuaDebugger::ReadWord( bool bNewLine/*=false*/ )
{
	if (bNewLine)
	{
        m_pBuf = NULL;
	}

    if( m_pBuf == NULL)
    {
		if (!bNewLine)
		{
            return NULL;
		}
		memset(m_szBuffer, 0, sizeof(m_szBuffer));
		XLog(LEVEL_DEBUG,"(adb) ");
#ifdef _WIN32
		if (!fgets(m_szBuffer, sizeof(m_szBuffer), stdin))
		{
            return NULL;
		}
#else
		char* psLine = readline(NULL);
		if (psLine == NULL)
		{
			return NULL;
		}
		strncpy(m_szBuffer, psLine, sizeof(m_szBuffer)-1);
		if (*m_szBuffer != '\0')
		{
			add_history(psLine);
		}
		SAFE_FREE(psLine);
#endif
        m_pBuf = m_szBuffer;
    }

    while( *m_pBuf == ' ' || *m_pBuf == '\t' )
        m_pBuf++;

    char* pCur = m_pBuf;
    while( *m_pBuf != ' ' && *m_pBuf != '\t' && *m_pBuf != '\n' && *m_pBuf != '\r' && *m_pBuf != 0 )
        m_pBuf++;				

    while( *m_pBuf == ' ' || *m_pBuf == '\t' )
    {
        *m_pBuf = 0;
        m_pBuf++;
    }

    if( *m_pBuf == 0 || *m_pBuf == '\n' || *m_pBuf == '\r')
    {
        *m_pBuf = 0;
        m_pBuf = NULL;
    }

    return pCur;
}

void LuaDebugger::HookProc( lua_State *pState, lua_Debug* pDebug )
{
	LuaWrapper::Instance()->GetDebugger()->LineHook( pState, pDebug );
}

void LuaDebugger::LineHook( lua_State *pState,lua_Debug* pDebug )
{
    bool bHitBreakPoint = HitBreakPoint(pState,pDebug);

	if(pState!=m_pState)
	{
		if(m_bInCoroutine)
			return;
		//转换了coroutine
		switch(pDebug->event)
		{
		case LUA_HOOKCALL:
			//resume
			if( m_nBreakStackLevel<=m_nRunningStackLevel )
			{
				//打开这个开关，在coroutine中运行的代码都不会触发任何调试器的状态变化
				m_bInCoroutine=true;
				return;
			}
			//step in
			//fall down
		case LUA_HOOKRET:
			//yield or dead
			m_pState=pState;
			SetStepIn();
			break;
		default:
			{
				XLog(LEVEL_DEBUG,"Invalid hook event %d when switching coroutine.", pDebug->event);
				return;
			}
		}

		if( !bHitBreakPoint )
			return;
	}
	else
	{
		if(m_nBreakStackLevel!=-1)
		{
			//单步执行是打开的
			switch(pDebug->event)
			{
			case LUA_HOOKCALL:
				//并不是每一次LUA_HOOKCALL都会增加堆栈深度
				m_nRunningStackLevel=GetRunStackDepth(m_pState);

				if(m_nBreakStackLevel<m_nRunningStackLevel)	//step out或者step over
					lua_sethook( pState, &LuaDebugger::HookProc, LUA_MASKCALL | LUA_MASKRET | (HaveBreakPoint()?LUA_MASKLINE:0), 0 );
				return;
			case LUA_HOOKRET:
				if(m_bInCoroutine)
					m_bInCoroutine=false;

				//并不是每一次LUA_HOOKRETURN都会减少堆栈深度
				m_nRunningStackLevel=GetRunStackDepth(m_pState)-1;

				if(m_nBreakStackLevel>=m_nRunningStackLevel)
					lua_sethook( pState, &LuaDebugger::HookProc, LUA_MASKCALL | LUA_MASKRET | LUA_MASKLINE, 0 );
				return;
			case LUA_HOOKTAILCALL:
				break;
			case LUA_HOOKLINE:
				break;
			default:
				XLog(LEVEL_DEBUG,"Invalid event in lua hook function");
				return;
			}

			if(  (!bHitBreakPoint) && (m_nBreakStackLevel>=0) && (m_nBreakStackLevel<m_nRunningStackLevel)  )
				return;

			m_nRunningStackLevel=m_nBreakStackLevel=-1;//关闭所有各类单步执行
		}
		else
		{
			if( !bHitBreakPoint || pDebug->event!=LUA_HOOKLINE )
				return;
		}
	}

	lua_sethook( pState, &LuaDebugger::HookProc, 0, 0 );

	Debug();
}

void LuaDebugger::SetStepNext()
{
    lua_sethook( m_pState, &LuaDebugger::HookProc, LUA_MASKLINE | LUA_MASKCALL | LUA_MASKRET, 0 );
    m_nRunningStackLevel=GetRunStackDepth(m_pState);
    m_nBreakStackLevel=m_nRunningStackLevel;	//栈级别必须与当前执行深度相同
}

void LuaDebugger::SetStepIn()
{
    lua_sethook( m_pState, &LuaDebugger::HookProc, LUA_MASKLINE | LUA_MASKCALL | LUA_MASKRET, 0 );
    m_nRunningStackLevel=GetRunStackDepth(m_pState);
    m_nBreakStackLevel=INT_MAX;					//无堆栈级别需求，任何情况都可以断
}


BreakPoint::BreakPoint( const char* szFileName,uint32_t uLineNum )
{
}

bool BreakPoint::operator<( const BreakPoint& ano ) const
{
    if(m_uLineNum<ano.m_uLineNum)
        return true;
    if(m_uLineNum>ano.m_uLineNum)
        return false;

    const char* szLeft=m_szFileName;
    const char* szRight=ano.m_szFileName;

    for(;;++szLeft,++szRight)
    {
        if(!*szLeft)
            return *szRight!=0;				

        if(!*szRight)
            return true;

        if( (*szLeft=='\\' || *szLeft=='/') && (*szRight=='\\' || *szRight=='/') )
            continue;

        if( tolower(*szLeft) < tolower(*szRight) )
            return true;
    }
}

bool BreakPoint::operator==( const BreakPoint& ano ) const
{
    if(m_uLineNum!=ano.m_uLineNum)
        return false;

    const char* szLeft=m_szFileName;
    const char* szRight=ano.m_szFileName;

    for(;;++szLeft,++szRight)
    {
        if(!*szLeft)
            return *szRight==0;

        if( (*szLeft=='\\' || *szLeft=='/') && (*szRight=='\\' || *szRight=='/') )
            continue;

        if( tolower(*szLeft) != tolower(*szRight) )
            return false;
    }
}

void BreakPoint::Store()
{
	if (m_szFileName == NULL)
	{
		return;
	}
    int32_t nLen = static_cast<int32_t>( strlen(m_szFileName)+1 );
	char* szBuffer = (char*)XALLOC(NULL, sizeof(char)*nLen);
    memcpy(szBuffer,m_szFileName,nLen);
    m_szFileName=szBuffer;
}

void BreakPoint::Clear()
{
	SAFE_FREE(m_szFileName);
}



// Register lua table seri
void RegLuaDebugger(const char* psTable)
{
	luaL_Reg aFuncList[] =
	{
		{ "adb", LuaDebugBreak},
		{ NULL, NULL },
	};
	LuaWrapper::Instance()->RegFnList(aFuncList, psTable);
}
