#ifndef __DETECTOR_H__
#define __DETECTOR_H__

#include "Server/LogicServer/GameObject/Object.h"

class Detector : public Object
{
public:
	LUNAR_DECLARE_CLASS(Detector);

public:
	Detector();
	virtual ~Detector();
	bool Init(int64_t nObjID, int nConfID, const char* psName);

public:

private:
	DISALLOW_COPY_AND_ASSIGN(Detector);


/////////////////lua export////////////
public:
};

#endif