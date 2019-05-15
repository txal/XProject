


CPVPActivityBaseRoleData = CPVPActivityBaseRoleData or class()
CPVPActivityBase = CPVPActivityBase or class()
CPVPActivityMgrBase = CPVPActivityMgrBase or class()

CSchoolArena = CSchoolArena or class(CPVPActivityBase)
CSchoolArenaMgr = CSchoolArenaMgr or class(CPVPActivityMgrBase)

CQimaiArena = CQimaiArena or class(CPVPActivityBase)
CQimaiArenaMgr = CQimaiArenaMgr or class(CPVPActivityMgrBase)

CQingyunBattle = CQingyunBattle or class(CPVPActivityBase)
CQingyunBattleMgr = CQingyunBattleMgr or class(CPVPActivityMgrBase)

CUnionArena = CUnionArena or class(CPVPActivityBase)
CUnionArenaMgr = CUnionArenaMgr or class(CPVPActivityMgrBase)

CPVPActivityMgr = CPVPActivityMgr or class()


require("PVPActivity/PVPActivityBase")
require("PVPActivity/PVPActivityMgrBase")
require("PVPActivity/SchoolArena")
require("PVPActivity/SchoolArenaMgr")
require("PVPActivity/QimaiArena")
require("PVPActivity/QimaiArenaMgr")
require("PVPActivity/QingyunBattle")
require("PVPActivity/QingyunBattleMgr")
require("PVPActivity/PVPActivityDef")
require("PVPActivity/PVPActivityMgr")
require("PVPActivity/PVPActivityRpc")
require("PVPActivity/UnionArena")
require("PVPActivity/UnionArenaMgr")



