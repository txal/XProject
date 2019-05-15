CHolidayActivityMgr = CHolidayActivityMgr or class(CModuleBase)
CHolidayActivityBase = CHolidayActivityBase or class()
CHolidayActAnswers = CHolidayActAnswers or class(CHolidayActivityBase)
CHolidayActExperience = CHolidayActExperience or class(CHolidayActivityBase)
CHolidayActTeachTest = CHolidayActTeachTest or class(CHolidayActivityBase)


require("Module/HolidayActivity/HolidayActivityDef")
require("Module/HolidayActivity/HolidayActivityBase")
require("Module/HolidayActivity/HolidayActAnswers")
require("Module/HolidayActivity/HolidayActExperience")
require("Module/HolidayActivity/HolidayActTeachTest")

require("Module/HolidayActivity/HolidayActivityMgr")
require("Module/HolidayActivity/HolidayActivityRpc")