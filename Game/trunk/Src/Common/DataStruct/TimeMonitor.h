#ifndef __TIMEMONITOR_H__
#define __TIMEMONITOR_H__

#include "Common/DataStruct/XTime.h"

class TimeMonitor
{
public:
	TimeMonitor()
	{
		Begin();
	}

public:
	void Begin()
	{
		m_uUSTime = XTime::USTime();
	}

	double End()
	{
		uint64_t uUS = XTime::USTime() - m_uUSTime;
		double fMS = uUS / 1000.0;
		return fMS;
	}

private:
	uint64_t m_uUSTime;
	DISALLOW_COPY_AND_ASSIGN(TimeMonitor);
};

#endif
