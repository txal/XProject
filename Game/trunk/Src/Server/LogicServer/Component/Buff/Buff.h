#ifndef __BUFF_H__
#define __BUFF_H__

#include "Common/Platform.h"

class Buff
{
public:
	Buff(int nBuffID, int nMSTime);
	~Buff();

	int GetID()	{ return m_nBuffID;  }
	bool IsExpired(int64_t nNowMS);		//是否过期
	void DelayTime(int nMSTime);		//延长时间
	void Restart();						//重新开始

private:
	int m_nBuffID;
	int m_nBuffTime;		//BUFF持续时间(MS)
	int64_t m_nExpiredTime;	//过期时间(MS)

	DISALLOW_COPY_AND_ASSIGN(Buff);
};

#endif
