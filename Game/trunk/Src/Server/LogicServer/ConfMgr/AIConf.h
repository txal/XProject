#ifndef __AICONF_H__
#define __AICONF_H__

#include "Common/Platform.h"
#include "Common/CSVDocument/CSVDocument.h"

struct AIConf
{
	uint16_t uID;
	int16_t tActRandom[2];
	int16_t tR1[2];	//攻击游走
	int16_t tR2[2];	//巡逻游走
	int16_t tR3[2];	//攻击距离
	int16_t tAtkTime[2];
	int16_t tDefTime[2];
	int16_t nAtkCD;
	int8_t nSwitchWeaponRate;
	int8_t nDropBombRate;
};

class AIConfMgr
{
public:
	typedef std::unordered_map<int, AIConf> ConfMap;
	typedef ConfMap::iterator ConfIter;

public:
	AIConf* GetConf(int nID);
	bool Init(CSVDocument* poCSVDoc);

private:
	ConfMap m_oConfMap;
};

#endif