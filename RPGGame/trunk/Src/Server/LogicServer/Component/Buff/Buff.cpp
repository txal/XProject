#include "Buff.h"
#include "Common/DataStruct/XTime.h"

Buff::Buff(int nBuffID, int nMSTime)
{
	m_nBuffID = nBuffID;
	m_nBuffTime = nMSTime;
	m_nExpiredTime = XTime::MSTime() + nMSTime;
}

Buff::~Buff()
{
	
}

bool Buff::IsExpired(int64_t nNowMS)
{
	return (nNowMS >= m_nExpiredTime);
}

void Buff::DelayTime(int nMSTime)
{
	m_nExpiredTime += nMSTime;
}

void Buff::Restart()
{
	m_nExpiredTime = XTime::MSTime() + m_nBuffTime;
}
