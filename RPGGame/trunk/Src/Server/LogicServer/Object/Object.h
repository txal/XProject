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
	int GetID()  { return m_nObjID; }
	char* GetName() { return m_sName; }
	int GetConfID() { return m_nConfID;  }
	GAMEOBJ_TYPE GetType() { return m_nObjType; }

	Point& GetPos() { return m_oPos; }
	void SetPos(const Point& oPos, const char* pFile = "", int nLine = 0);
	Scene* GetScene() { return m_poScene; }
	int GetAOIID() { return m_nAOIID; }

	bool IsTime2Collect(int64_t nNowMS);
	int64_t GetLastUpdateTime() { return m_nLastUpdateTime; }

public:
	virtual void OnEnterScene(Scene* poScene, int nAOIID, const Point& oPos);
	virtual void AfterEnterScene();
	virtual void OnLeaveScene();

public:
	void CacheActorNavi(uint16_t nTarServer=0, int nTarSession=0);	//如果传参表示也发给自己

protected:
	int m_nObjID;
	int m_nConfID;
	char m_sName[64];
	GAMEOBJ_TYPE m_nObjType;

	Scene* m_poScene;
	int m_nAOIID;
	Point m_oPos;

	int64_t m_nLeaveSceneTime;
	int64_t m_nLastUpdateTime;

	DISALLOW_COPY_AND_ASSIGN(Object);

////////////////lua export//////////////////////
public:
	int GetName(lua_State* pState);
	int GetObjID(lua_State* pState);
	int GetConfID(lua_State* pState);
	int GetObjType(lua_State* pState);
	int GetDupMixID(lua_State* pState);
	int GetAOIID(lua_State* pState);
	int GetPos(lua_State* pState);
};


#define DECLEAR_OBJECT_METHOD(Class) \
LUNAR_DECLARE_METHOD(Class, GetName),\
LUNAR_DECLARE_METHOD(Class, GetObjID),\
LUNAR_DECLARE_METHOD(Class, GetConfID),\
LUNAR_DECLARE_METHOD(Class, GetObjType),\
LUNAR_DECLARE_METHOD(Class, GetDupMixID),\
LUNAR_DECLARE_METHOD(Class, GetAOIID),\
LUNAR_DECLARE_METHOD(Class, GetPos)


//注册到LUA
void RegClassObject();


#endif