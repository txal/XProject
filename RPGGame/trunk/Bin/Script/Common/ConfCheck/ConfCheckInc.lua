
ConfCheckBase = ConfCheckBase or class()

local tLogicServiceList = {50, 100, 101, 102}
local function _fnDiscardTable(sTableName)
	local nServiceID = GF and GF.GetServiceID() or nil
	if not table.InArray(nServiceID, tLogicServiceList) then
		_G[sTableName] = nil
		if LuaTrace then
			LuaTrace("Discard table:", sTableName, "service:", nServiceID)
		end
	end
end

require("Common/ConfCheck/ConfCheckBase")
require("Common/ConfCheck/LangConfCheck")
require("Common/ConfCheck/RoleInitConfCheck")
require("Common/ConfCheck/RechargeConfCheck")
require("Common/ConfCheck/GiftConfCheck")
require("Common/ConfCheck/AwardPoolConfCheck")
require("Common/ConfCheck/AIConfCheck")
require("Common/ConfCheck/AISkillConfCheck")
require("Common/ConfCheck/ShangJinTaskConfCheck")
require("Common/ConfCheck/RandPointConfCheck")
require("Common/ConfCheck/PropConfCheck")
require("Common/ConfCheck/ShiLianTaskConfCheck")
require("Common/ConfCheck/HolidayActivityConfCheck")
require("Common/ConfCheck/DupConfCheck")
require("Common/ConfCheck/ExchangeActivityConfCheck")
require("Common/ConfCheck/ArenaRobotConfCheck")
require("Common/ConfCheck/TaskSystemConfCheck")
require("Common/ConfCheck/ShiMenTaskConfCheck")
require("Common/ConfCheck/ShiZhuangConfCheck")
require("Common/ConfCheck/TianDiBaoWuConfCheck")
require("Common/ConfCheck/TargetTaskConfCheck")
require("Common/ConfCheck/ShenMoZhiConfCheck")
require("Common/ConfCheck/GuaJiConfCheck")
require("Common/ConfCheck/MarriageConfCheck")
require("Common/ConfCheck/PalanquinWayConfCheck")
require("Common/ConfCheck/PVEActivityConfCheck")
require("Common/ConfCheck/WillOpenConfCheck")
require("Common/ConfCheck/FindAwardConfCheck")
require("Common/ConfCheck/FormationConfCheck")
require("Common/ConfCheck/EverydayGiftConfCheck")
require("Common/ConfCheck/RoleNamePoolConfCheck")
require("Common/ConfCheck/BattleGroupConfCheck")
require("Common/ConfCheck/PasSkillConfCheck")
require("Common/ConfCheck/RoleGrowthConfCheck")

--配置表太大，不需要的服务就不加载了
_fnDiscardTable("ctSubMonsterConf")