#include "ConfMgr.h"

std::string sCSVDir = "../Data/Config/CSV/";

ConfMgr* ConfMgr::Instance()
{
	static ConfMgr oSingleton;
	return &oSingleton;
}

void ConfMgr::LoadConf()
{
	LOAD_CSV_CONF(m_oMapConfMgr, sCSVDir+"Map/MapConf.csv");
	LOAD_CSV_CONF(m_oAIConfMgr, sCSVDir+"AI/AIConf.csv");
}