#ifndef __CONFMGR_H__
#define __CONFMGR_H__

#include "Common/Platform.h"
#include "Include/Logger/Logger.hpp"
#include "Common/CSVDocument/CSVDocument.h"

#include "MapConf.h"
#include "AIConf.h"

#define LOAD_CSV_CONF(oInst, sCSVFile) { \
	CSVDocument* poDoc = ConfMgr::Instance()->GetDocument(); \
	int nErrRow = 0, nErrCol = 0; \
	poDoc->load((sCSVFile), true, &nErrRow, &nErrCol); \
	if (nErrRow != 0 || nErrCol != 0) \
	{ XLog(LEVEL_ERROR, "Conf '%s' Row:%d Col:%d error!\n", (sCSVFile).c_str()); return; } \
	if (!oInst.Init(poDoc)) { return; } \
}

class ConfMgr
{
public:
	static ConfMgr* g_poConfMgr;
	static ConfMgr* Instance();
	static void Release();

	CSVDocument* GetDocument()	{ return &m_oCSVDoc;  }
	void LoadConf(std::string dataPath);

public:
	MapConfMgr* GetMapMgr()		{ return &m_oMapConfMgr;  }
	AIConfMgr* GetAIMgr()		{ return &m_oAIConfMgr;  }
	std::string& GetDataPath()	{ return m_oDataPath;  }

private:
	MapConfMgr m_oMapConfMgr;	//地图配置
	AIConfMgr m_oAIConfMgr;		//AI配置


private:
	ConfMgr() {};
	~ConfMgr() {};
	CSVDocument m_oCSVDoc;
	std::string m_oDataPath;
	DISALLOW_COPY_AND_ASSIGN(ConfMgr);
};

#endif