#ifndef __OBJECT_H__
#define __OBJECT_H__

#include "Include/Script/Script.hpp"
#include "Common/DataStruct/Point.h"
#include "Common/PacketParser/PacketReader.h"
#include "Common/PacketParser/PacketWriter.h"
#include "Server/Base/ServerContext.h"
#include "Server/LogicServer/GameObject/ObjectDef.h"

class SceneBase;

class Object
{
public:
	LUNAR_DECLARE_CLASS(Object);

public:
	Object();
	virtual ~Object();

	void Init(OBJTYPE nObjType, int64_t nObjID, int nConfID, const char* psName);
	
public:
	OBJTYPE GetType() { return m_nObjType; }
	int GetConfID() { return m_nConfID;  }
	int64_t GetID() { return m_nObjID; }
	char* GetName() { return m_sName; }

	Point& GetPos() { return m_oPos; }
	int GetAOIID() { return m_nAOIID; }
	SceneBase* GetScene() { return m_poScene; }

	void SetPos(const Point& oPos);
	void SetFace(int8_t nFace) { m_nFace = nFace; }

	int64_t GetLastRunUpdateTime() { return m_nLastRunUpdateTime; }
	int64_t GetLastViewUpdateTime() { return m_nLastViewUpdateTime; }

	bool IsDeleted() { return m_bIsDeleted; }
	void MarkDeleted() { m_bIsDeleted = true; }

public:
	virtual void Update(int64_t nNowMS);
	virtual void UpdateViewList(int64_t nNowMS);
	virtual void UpdateRunState(int64_t nNowMS) {}

	virtual void OnEnterScene(SceneBase* poScene, int nAOIID, Point& oPos);
	virtual void OnLeaveScene();

	virtual int GetSession() { return 0; }
	virtual uint16_t GetServer() { return 0; }

	virtual void BroadcastPos(bool bSelf) {}

public:
	void CacheObjNavi(uint16_t nSelfServer=0, int nSelfSession=0);


protected:
	int m_nLuaObjRef;
	int64_t m_nObjID;
	int m_nConfID;
	char m_sName[64];
	OBJTYPE m_nObjType;

	int m_nAOIID;
	Point m_oPos;
	int8_t m_nFace;
	SceneBase* m_poScene;

	int64_t m_nLeaveSceneTime;
	int64_t m_nLastRunUpdateTime;
	int64_t m_nLastViewUpdateTime;
	bool m_bIsDeleted;

private:
	DISALLOW_COPY_AND_ASSIGN(Object);

////////////////lua export//////////////////////
public:
	int GetName(lua_State* pState);
	int GetObjID(lua_State* pState);
	int GetConfID(lua_State* pState);
	int GetObjType(lua_State* pState);
	int GetSceneID(lua_State* pState);
	int GetServerID(lua_State* pState);
	int GetSessionID(lua_State* pState);
	int GetAOIID(lua_State* pState);
	int GetPos(lua_State* pState);
	int SetPos(lua_State* pState);
	int GetFace(lua_State* pState);
	int GetLine(lua_State* pState);
	int SetLine(lua_State* pState);
	int GetLuaObj(lua_State* pState);
	int BindLuaObj(lua_State* pState);
};


#define DECLEAR_OBJECT_METHOD(Class) \
LUNAR_DECLARE_METHOD(Class, GetName),\
LUNAR_DECLARE_METHOD(Class, GetObjID),\
LUNAR_DECLARE_METHOD(Class, GetConfID),\
LUNAR_DECLARE_METHOD(Class, GetObjType),\
LUNAR_DECLARE_METHOD(Class, GetSceneID),\
LUNAR_DECLARE_METHOD(Class, GetServerID),\
LUNAR_DECLARE_METHOD(Class, GetSessionID),\
LUNAR_DECLARE_METHOD(Class, GetAOIID),\
LUNAR_DECLARE_METHOD(Class, GetPos),\
LUNAR_DECLARE_METHOD(Class, SetPos),\
LUNAR_DECLARE_METHOD(Class, GetFace),\
LUNAR_DECLARE_METHOD(Class, GetLine),\
LUNAR_DECLARE_METHOD(Class, SetLine),\
LUNAR_DECLARE_METHOD(Class, GetLuaObj),\
LUNAR_DECLARE_METHOD(Class, BindLuaObj)


//注册到LUA
void RegClassObject();


#endif