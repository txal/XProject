#ifndef __FOLLOW_H__
#define __FOLLOW_H__

#include "Common/DataStruct/Point.h"
#include "Server/LogicServer/Object/ObjectDef.h"

struct FOLLOW
{
	int nObjType;
	int nObjID;

	FOLLOW(int _objType = 0, int _objID = 0)
	{
		nObjType = _objType;
		nObjID = _objID;
	}
	FOLLOW(const int64_t _mixID)
	{
		nObjType = (int)(_mixID >> 32);
		nObjID = (int)(_mixID & 0xFFFFFFFF);
	}
	int64_t ToInt64()
	{
		return ((int64_t)nObjType << 32 | nObjID);
	}
};

class Follow 
{
public:
	typedef std::vector<FOLLOW> FollowVec;
	typedef std::unordered_map<int64_t, FollowVec*> FollowMap;
	typedef FollowMap::iterator FollowIter;

public:
	Follow();
	virtual ~Follow();
	virtual void Update(int64_t nNowMS);

public:
	FollowVec* GetFollowList(int nObjType, int nObjID);
	FollowVec* CreateFollowList(int nObjType, int nObjID);
	void RemoveateFollowList(int nObjType, int nObjID);
	
protected:
	FollowMap m_oFollowMap;		//跟随关系表

	DISALLOW_COPY_AND_ASSIGN(Follow);

};

#endif