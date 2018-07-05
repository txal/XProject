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

	typedef std::vector<int> FollowVec;
	typedef FollowVec::iterator FollowIter;

public:
	Object();
	virtual ~Object();
	virtual void Update(int64_t nNowMS);
	
public:
	int GetID()  { return m_nObjID; }
	char* GetName() { return m_sName; }
	int GetConfID() { return m_nConfID;  }
	GAMEOBJ_TYPE GetType() { return m_nObjType; }

	int GetAOIID() { return m_nAOIID; }
	Point& GetPos() { return m_oPos; }
	void SetPos(const Point& oPos, const char* pFile = "", int nLine = 0);
	Scene* GetScene() { return m_poScene; }
	void SetFace(int8_t nFace) { m_nFace = nFace; }

	bool IsTime2Collect(int64_t nNowMS);
	int64_t GetLastUpdateTime() { return m_nLastUpdateTime; }


public:
	virtual void OnEnterScene(Scene* poScene, int nAOIID, const Point& oPos, int8_t nLine=0);
	virtual void AfterEnterScene();
	virtual void OnLeaveScene();
	virtual uint16_t GetServer() { return 0; }
	virtual int GetSession() { return 0; }

public:
	void CacheActorNavi(uint16_t nTarServer=0, int nTarSession=0);	//如果传参表示也发给自己
	virtual void BroadcastPos(bool bSelf) {}
	void SetFollowTarget(int64_t nTarObjID) { m_nFollowTarget = nTarObjID; }
	int64_t GetFollowTarget() { return m_nFollowTarget; }


protected:
	int m_nObjID;
	int m_nConfID;
	char m_sName[64];
	GAMEOBJ_TYPE m_nObjType;

	Scene* m_poScene;
	int m_nAOIID;
	Point m_oPos;
	int8_t m_nFace;
	int8_t m_nLine;

	int64_t m_nLeaveSceneTime;
	int64_t m_nLastUpdateTime;

	int64_t m_nFollowTarget; //跟随的目标类型>>32|ID

	DISALLOW_COPY_AND_ASSIGN(Object);

////////////////lua export//////////////////////
public:
	int GetName(lua_State* pState);
	int GetObjID(lua_State* pState);
	int GetConfID(lua_State* pState);
	int GetObjType(lua_State* pState);
	int GetDupMixID(lua_State* pState);
	int GetServerID(lua_State* pState);
	int GetSessionID(lua_State* pState);
	int GetAOIID(lua_State* pState);
	int GetPos(lua_State* pState);
	int SetPos(lua_State* pState);
	int GetFace(lua_State* pState);
	int GetLine(lua_State* pState);
	int SetLine(lua_State* pState);
};


#define DECLEAR_OBJECT_METHOD(Class) \
LUNAR_DECLARE_METHOD(Class, GetName),\
LUNAR_DECLARE_METHOD(Class, GetObjID),\
LUNAR_DECLARE_METHOD(Class, GetConfID),\
LUNAR_DECLARE_METHOD(Class, GetObjType),\
LUNAR_DECLARE_METHOD(Class, GetDupMixID),\
LUNAR_DECLARE_METHOD(Class, GetServerID),\
LUNAR_DECLARE_METHOD(Class, GetSessionID),\
LUNAR_DECLARE_METHOD(Class, GetAOIID),\
LUNAR_DECLARE_METHOD(Class, GetPos),\
LUNAR_DECLARE_METHOD(Class, SetPos),\
LUNAR_DECLARE_METHOD(Class, GetFace),\
LUNAR_DECLARE_METHOD(Class, GetLine),\
LUNAR_DECLARE_METHOD(Class, SetLine)


//注册到LUA
void RegClassObject();


#endif