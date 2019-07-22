#ifndef __DETECTOR_H__
#define __DETECTOR_H__

#include "Server/LogicServer/Object/Object.h"

class Detector : public Object
{
public:
	LUNAR_DECLARE_CLASS(Detector);

public:
	Detector();
	virtual ~Detector();
	void Init(int64_t nObjID, int nConfID, const char* psName);

public:
	virtual void Update(int64_t nNowMS);

private:
	DISALLOW_COPY_AND_ASSIGN(Detector);


/////////////////lua export////////////
public:
};

#endif