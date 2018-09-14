#include "Server/LogicServer/ConfMgr/ConfMgr.h"

ConfMgr* ConfMgr::Instance()
{
	static ConfMgr oSingleton;
	return &oSingleton;
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