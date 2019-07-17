CNpcMgr = CNpcMgr or class()
CNpcBase = CNpcBase or class()
CNpcTalk = CNpcTalk or class(CNpcBase)
CNpcFunc = CNpcFunc or class(CNpcBase)
CNpcGoldBox = CNpcGoldBox or class(CNpcBase)

require("NpcFunc/NpcDef")
require("NpcFunc/NpcBase")
require("NpcFunc/NpcTalk")
require("NpcFunc/NpcFunc")
require("NpcFunc/NpcGoldBox")

require("NpcFunc/NpcMgr")
require("NpcFunc/NpcRpc")