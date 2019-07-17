CCBMgr = CCBMgr or class()

CCBBase = CCBBase or class(CHDBase)
CRechargeCB = CRechargeCB or class(CCBBase)
CResumeYBCB = CResumeYBCB or class(CCBBase)


require("HDMgr/CB/CBBase")
require("HDMgr/CB/RechargeCB")
require("HDMgr/CB/ResumeYBCB")


require("HDMgr/CB/CBMgr")
require("HDMgr/CB/CBRpc")