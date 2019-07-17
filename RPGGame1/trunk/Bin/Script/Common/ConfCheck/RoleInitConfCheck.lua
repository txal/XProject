local function _RoleInitConfCheck()
    for _, tConf in pairs(ctRoleInitConf) do 
        for k, nEquID in ipairs(tConf.tBornEquipment[1]) do 
            if not ConfCheckBase:CheckItemExist(gtItemType.eProp, nEquID) then 
                assert(false, string.format("角色初始表ID(%d),装备道具(%d)道具表中不存在", tConf.nID, nEquID))
            end
            if not ctEquipmentConf[nEquID] then 
                assert(false , string.format("角色初始表ID(%d),装备道具(%d)装备表中不存在", tConf.nID, nEquID))
            end
        end
    end
end
_RoleInitConfCheck()