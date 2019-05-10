#include "Server/LogicServer/ConfMgr/ConfMgr.h"

ConfMgr* ConfMgr::g_poConfMgr = NULL;

ConfMgr* ConfMgr::Instance()
{
	if (g_poConfMgr == NULL)
	{
		g_poConfMgr = XNEW(ConfMgr);
	}
	return g_poConfMgr;
}

void ConfMgr::Release()
{
	SAFE_DELETE(g_poConfMgr);
}


void ConfMgr::LoadConf(std::string dataPath)
{
	if (dataPath == "")
	{
		dataPath = "../../";
	}
	m_oDataPath = dataPath;
	dataPath = dataPath + "/Data/Config/CSV/";
	LOAD_CSV_CONF(m_oMapConfMgr, dataPath+"MapConf.csv");
	//LOAD_CSV_CONF(m_oAIConfMgr, sCSVDir+"AIConf.csv");
}