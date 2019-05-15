

function _ArenaRobotConfCheck()
    for _, tConf in pairs(ctArenaRobotConf) do 
        if not ctRoleInitConf[tConf.nRoleConfID] then 
            assert(false, string.format("竞技场机器人配置ID(%d),nRoleConfID(%d)配置不存在", tConf.nID, tConf.nRoleConfID))
        end
        if not ctSubMonsterConf[tConf.nAttrConf] then 
            assert(false, string.format("竞技场机器人配置ID(%d),nAttrConf(%d)配置不存在", tConf.nID, tConf.nAttrConf))
        end
        if not ctPetInfoConf[tConf.nPetID] then 
            assert(false, string.format("竞技场机器人配置ID(%d),nPetID(%d)配置不存在", tConf.nID, tConf.nPetID))
        end
        if not ctSubMonsterConf[tConf.nPetAttr] then 
            assert(false, string.format("竞技场机器人配置ID(%d),nPetAttr(%d)配置不存在", tConf.nID, tConf.nPetAttr))
        end
        for k, v in pairs(tConf.tPartner) do 
            if not ctPartnerConf[v[1]] then 
                assert(false, string.format("竞技场机器人配置ID(%d),tPartner(%d)配置不存在", tConf.nID, v[1]))
            end
        end
    end
end

_ArenaRobotConfCheck()

