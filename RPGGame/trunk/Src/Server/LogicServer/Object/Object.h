#ifndef __OBJECT_H__
#define __OBJECT_H__

#include "Include/Script/Script.hpp"
#include "Common/DataStruct/Point.h"
#include "Common/PacketParser/PacketReader.h"
#include "Common/PacketParser/PacketWriter.h"
#include "Server/Base/ServerContext.h"
#include "Server/LogicServer/Object/ObjectDef.h"

class Scene;
class Object
{
public:
	LUNAR_DECLARE_CLASS(Object);

public:
	Object();
	virtual ~Object();
	virtual void Update(int64_t nNowMS);
	
public:
	char* GetName()						{ return m_sName; }
	int GetConfID()						{ return m_nConfID;  }
	int GetID() 						{ return m_nObjID; }
	GAME_OBJ_TYPE GetType()				{ return m_nObjType; }

	Point& GetPos() 					{ return m_oPos;  }
	void SetPos(const Point& oPos, const char* pFile = "", int nLine = 0);
	Scene* GetScene()					{ return m_poScene; }
	int GetAOIID()						{ return m_nAOIID;  }

	bool IsTimeToCollected(int64_t nNowMS);
	int64_t GetLastUpdateTime()			{ return m_nLastUpdateTime; }

public:
	virtual void OnEnterScene(Scene* poScene,const Point& oPos, int nAOIID);
	virtual void AfterEnterScene();
	virtual void OnLeaveScene();
	virtual bool CheckCamp(Object* poTar);	//阵营可攻击返回true
	virtual void OnBattleResult() {}

public:
	void CacheActorNavi(uint16_t nTarServer = 0, int nTarSession = 0);	//如果传参表示也发给自己

protected:
	int m_nConfID;
	char m_sName[64];
	int m_nObjID;
	GAME_OBJ_TYPE m_nObjType;

	int64_t m_nLeaveSceneTime;
	int64_t m_nLastUpdateTime;

	int m_nAOIID;
	Point m_oPos;
	Scene* m_poScene;

	int8_t m_nCamp;
	DISALLOW_COPY_AND_ASSIGN(Object);

	


////////////////lua export//////////////////////
public:
	int GetObjID(lua_State* pState);
	int GetConfID(lua_State* pState);
	int GetObjType(lua_State* pState);
	int GetName(lua_State* pState);
	int GetSceneIndex(lua_State* pState);
	int GetAOIID(lua_State* pState);
	int GetPos(lua_State* pState);
	int GetCamp(lua_State* pState);
	int SetCamp(lua_State* pState);
};


#define DECLEAR_OBJECT_METHOD(Class) \
LUNAR_DECLARE_METHOD(Class, GetObjID),\
LUNAR_DECLARE_METHOD(Class, GetConfID),\
LUNAR_DECLARE_METHOD(Class, GetObjType),\
LUNAR_DECLARE_METHOD(Class, GetName),\
LUNAR_DECLARE_METHOD(Class, GetSceneIndex),\
LUNAR_DECLARE_METHOD(Class, GetAOIID),\
LUNAR_DECLARE_METHOD(Class, GetPos),\
LUNAR_DECLARE_METHOD(Class, GetCamp),\
LUNAR_DECLARE_METHOD(Class, SetCamp)


//Register to lua
void RegClassObject();


#endif