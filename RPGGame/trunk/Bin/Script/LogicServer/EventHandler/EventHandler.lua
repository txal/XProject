--事件处理
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--完成一环师门任务
function CEventHandler:OnCompShiMenTask(oRole, tData)
    oRole.m_oTargetTask:OnEventHandler(gtTargetTask.eCompShiMenTask, 1, true)
end

--完成一次乱世妖魔
function CEventHandler:OnCompLuanShiYaoMo(oRole, tData)
    oRole.m_oTargetTask:OnEventHandler(gtTargetTask.eCompLuanshiYaoMo, 1, true)   

    -- if tData and tData.bIsHearsay then
    --     local sRoleName = oRole:GetName()
    --     local tHearsayConf = ctHearsayConf["fbluanshidrop"]
    --     assert(tHearsayConf, "没有传闻配置")
    --     for _, tHearsayCond in pairs(tHearsayConf.tParam) do
    --         if tData.nItemID == tHearsayCond[1] then
    --             local sCont = string.format(tHearsayConf.sHearsay, sRoleName, ctPropConf[tData.nItemID].sName)
    --             GF.SendHearsayMsg(sCont)
    --         end
    --     end
    -- end
end

--完成一次镇妖
function CEventHandler:OnCompZhenYao(oRole, tData)
    oRole.m_oTargetTask:OnEventHandler(gtTargetTask.eCompZhenYao, 1, true) 

    if tData and tData.bIsHearsay then
        local sRoleName = oRole:GetName()
        local tHearsayConf1 = ctHearsayConf["fbzhenyaodrop"]
        local tHearsayConf2 = ctHearsayConf["zhenyaoreward"]
        assert(tHearsayConf1 and tHearsayConf2, "没有传闻配置")
        tData.tItemIDList = tData.tItemIDList or {}
        if not next(tData.tItemIDList) then return end
        for _, tItem in pairs(tData.tItemIDList) do
            for _, tHearsayCond in pairs(tHearsayConf1.tParam) do
                if tItem[1] == tHearsayCond[1] then
                    local sCont = string.format(tHearsayConf1.sHearsay, sRoleName, ctPropConf[tItem[1]].sName)
                    GF.SendHearsayMsg(sCont)
                end
            end
            for _, tHearsayCond in pairs(tHearsayConf2.tParam) do
                if tItem[1] == tHearsayCond[1] then
                    local sCont = string.format(tHearsayConf2.sHearsay, sRoleName, tItem[2])
                    GF.SendHearsayMsg(sCont)
                end
            end
        end
    end       
end

--挖宝一次
function CEventHandler:OnCompBaoTu(oRole, tData)
    oRole.m_oTargetTask:OnEventHandler(gtTargetTask.eCompBaoTu, 1, true)
    oRole.m_oDailyActivity:OnCompleteDailyOnce(gtDailyID.eBaoTu, "挖宝成功")
    --传闻
    if tData and tData.bIsHearsay then
        local sKey
        if tData.nWaBaoType == CBaoTu.tWaBao.eNormal then
            sKey = "normalwabao"        --ctHearsayConf
        elseif tData.nWaBaoType == CBaoTu.tWaBao.eSpecial then
            sKey = "specailwabao"
        end
        local bHearsay = false
        local tConf = ctHearsayConf[sKey]
        for nIndex, tItem in pairs(tConf.tParam) do
            if tData.nItemID == tItem[1] then
                bHearsay = true
                break
            end
        end
        if bHearsay then
            local sCont = string.format(tConf.sHearsay, oRole:GetName(), ctPropConf[tData.nItemID].sName)
            GF.SendHearsayMsg(sCont)
        end
    end
end

--签到一次
function CEventHandler:OnSignIn(oRole, tData)
    oRole.m_oTargetTask:OnEventHandler(gtTargetTask.eSignIn, 1, true)
end

--帮派签到
function CEventHandler:OnUnionSignIn(oRole, tData)
    oRole.m_oTargetTask:OnEventHandler(gtTargetTask.eUnionSignIn, 1, true)
end

--宠物洗髓
function CEventHandler:OnPetWashAttr(oRole, tData)
    oRole.m_oTargetTask:OnEventHandler(gtTargetTask.ePetWashAttr, 1, true)
    oRole.m_oGuideTask:OnEventHandler(gtGuideTask.eWashPetAttr, 1, true)
    if tData and tData.bIsHearsay then
        local sRoleName = oRole:GetName()
        local tHearsayConf = ctHearsayConf["petxisui"]
        assert(tHearsayConf, "没有传闻配置")
        for _, tHearsayCond in pairs(tHearsayConf.tParam) do
            if tData.nPetType == tHearsayCond[1] then
                local sCont = string.format(tHearsayConf.sHearsay, sRoleName, tData.sPetName)
                GF.SendHearsayMsg(sCont)
                break
            end
        end
    end
end

--月老物品刷新
function CEventHandler:OldManItemRefresh(tData)
    local tHearsayConf = ctHearsayConf["oldmanrefresh"]
    assert(tHearsayConf, "没有传闻配置")
     local sCont = tHearsayConf.sHearsay
    GF.SendHearsayMsg(sCont)
end

--宠物学习技能
function CEventHandler:OnPetLearnSkill(oRole, tData)
    oRole.m_oTargetTask:OnEventHandler(gtTargetTask.ePetLearnSkill, 1, true)
    oRole.m_oGuideTask:OnEventHandler(gtGuideTask.ePetLearnSkill, 1, true)
end

--膜拜(祝贺)大神
function CEventHandler:OnCongratulate(oRole, tData)
    oRole.m_oTargetTask:OnEventHandler(gtTargetTask.eCongratulate, 1, true)
end

--参加竞技场
function CEventHandler:OnJoinArenaBattle(oRole, tData)
    oRole.m_oTargetTask:OnEventHandler(gtTargetTask.eJoinArenaBattle, 1, true)
end

--挖取灵石
function CEventHandler:OnExcavateStone(oRole, tData)
    oRole.m_oTargetTask:OnEventHandler(gtTargetTask.eExcavateStone, 1, true)
    oRole.m_oGuideTask:OnEventHandler(gtGuideTask.eExcavateStone, 1, true)
end

--赠送东西给仙侣
function CEventHandler:OnGiveSthToPartner(oRole, tData)
    oRole.m_oTargetTask:OnEventHandler(gtTargetTask.eGiveSthToPartner, tData.nAddNum, true)
    oRole.m_oGuideTask:OnEventHandler(gtGuideTask.eGiveSthToPartner, tData.nAddNum, true)
end

--领取在线礼包
function CEventHandler:OnGetOnlineGift(oRole, tData)
    oRole.m_oTargetTask:OnEventHandler(gtTargetTask.eGetOnlineGift, 1, true)
end

--完成一次赏金任务
function CEventHandler:OnCompShangJin(oRole, tData)
    oRole.m_oTargetTask:OnEventHandler(gtTargetTask.eCompShangJin, 1, true)
    if tData and tData.bIsHearsay then
        local sRoleName = oRole:GetName()
        local sTaskName = ctShangJinTaskConf[tData.nTaskID].sName
        local tConf = ctHearsayConf["compshangjinTask"]
        local bCanHearsay = false
        if not next(tData.tItemIDList) then return end
        for _, nItemID in pairs(tData.tItemIDList) do
            for _, tCond in pairs(tConf.tParam) do
                if nItemID == tCond[1] then
                    local sItemName = ctPropConf[nItemID].sName
                    local sCont = string.format(tConf.sHearsay, sRoleName, sTaskName, sItemName)
                    GF.SendHearsayMsg(sCont)
                end
            end
        end 
    end
    
end

--使用摄魂
function CEventHandler:OnUseDrawSpirit(oRole, tData)
    oRole.m_oTargetTask:OnEventHandler(gtTargetTask.eUseDrawSpirit, 1, true)
end

--提升战斗力
function CEventHandler:OnFightCapacityChange(oRole, tData)
    oRole.m_oTargetTask:OnEventHandler(gtTargetTask.eFightCapacity, tData.nPower, false)
end

--完成主线任务
function CEventHandler:OnCompPrinTask(oRole, tData)
    oRole.m_oTargetTask:OnEventHandler(gtTargetTask.eAchievePrinTask, tData.nTaskID, false)
end

--装备强化
function CEventHandler:OnEquStrenghten(oRole, tData)
    --策划确定记录强化过程以判断是否达到目标任务(换句话说，当前可能没有2件+5的装备，当曾经强化到有2件+5的装备也算完成)
    local tStrenghtenMap =  oRole.m_oTargetTask:GetCurrTargetData(gtTargetTask.eEquStrenghten) or {}    --{[StrenghtenLevel]=Num}
    local nOldNum = tStrenghtenMap[tData.nStrenghtenLevel] or 0
    tStrenghtenMap[tData.nStrenghtenLevel] = nOldNum + 1
    oRole.m_oTargetTask:OnEventHandler(gtTargetTask.eEquStrenghten, tStrenghtenMap, false)

    if tData and tData.bIsHearsay then
        local tConf = ctHearsayConf["strengthenequ"]
        local bCanHearsay = false
        for _, tCond in pairs(tConf.tParam) do
            if tData.nStrenghtenLevel >= tCond[1] then
                bCanHearsay = true 
                break
            end
        end 
        if bCanHearsay then
            local tEquType = {"武器", "帽子", "衣服", "项链", "腰带", "鞋子"}
            local sEquName = ctPropConf[tData.nEquID].sName
            local nLevel = ctEquipmentConf[tData.nEquID].nEquipLevel
            local nEquType = ctEquipmentConf[tData.nEquID].nEquipPartType
            local sEquType = tEquType[nEquType]
            local sCont = string.format(tConf.sHearsay, oRole:GetName(), nLevel, sEquType, sEquName, tData.nStrenghtenLevel)
            GF.SendHearsayMsg(sCont)
            print("发送装备强化传闻信息:", sCont)
        end
    end
end

--摄魂升级
function CEventHandler:OnDrawSpriritUpLevel(oRole, tData)
    oRole.m_oTargetTask:OnEventHandler(gtTargetTask.eDrawSpriritLevel, tData.nLevel, false)
end

--成为好友
function CEventHandler:OnBecomeFriend(oRole, tData)
    oRole.m_oTargetTask:OnEventHandler(gtTargetTask.eFriendNum, tData.nFriendNum, false)
end

--人物等级
function CEventHandler:OnRoleLevelChange(oRole, tData)
    oRole.m_oTargetTask:OnEventHandler(gtTargetTask.eRoleLevel, tData.nNewLevel, false)
end

--修炼等级改变
function CEventHandler:OnPracticeLevelChange(oRole, tData)
    local tSkillLevelMap = oRole.m_oTargetTask:GetCurrTargetData(gtTargetTask.ePracticeLevel) or {}
    for _, tLevel in ipairs(tData) do
        local nOldNum = tSkillLevelMap[tLevel.nLevel] or 0
        tSkillLevelMap[tLevel.nLevel] = nOldNum + 1
    end
    oRole.m_oTargetTask:OnEventHandler(gtTargetTask.ePracticeLevel, tSkillLevelMap, false)
end

--门派技能改变
function CEventHandler:OnSchoolSkillChange(oRole, tData)
    local tSkillLevelMap = oRole.m_oTargetTask:GetCurrTargetData(gtTargetTask.eSchoolSkill) or {}
    for nLevel, nNum in pairs(tData.tSkillLevelMap) do
        local nOldNum = tSkillLevelMap[nLevel] or 0
        tSkillLevelMap[nLevel] = nOldNum + nNum
    end
    oRole.m_oTargetTask:OnEventHandler(gtTargetTask.eSchoolSkill, tSkillLevelMap, false)
end

--战斗训练
function CEventHandler:OnBattleTrain(oRole, tData)
    oRole.m_oTargetTask:OnEventHandler(gtTargetTask.eBattleTrain, 1, true)
end

--开随机礼包
function CEventHandler:OnOpenGift(oRole, tData)
    if tData and tData.bIsHearsay then
        local tConf = ctHearsayConf["openrandgift"]
        local sRoleName = oRole:GetName()
        assert(ctGiftConf[tData.nGiftID], "不存在此礼包")
        local sGiftName = ctGiftConf[tData.nGiftID].sName
        for _, nItemID in pairs(tData.tItemIDList) do
            for _, tItem in pairs(tConf.tParam) do
                if nItemID == tItem[1] then
                    local sItemName = ctPropConf[nItemID].sName
                    local sCont = string.format(tConf.sHearsay, sRoleName, sGiftName, sItemName)
                    GF.SendHearsayMsg(sCont)
                end
            end
        end
    end
end

--开福缘宝箱
function CEventHandler:OnOpenGoldBox(oRole, tData)
    if tData and tData.bIsHearsay then
        local sRoleName = oRole:GetName()
        local tConf = ctHearsayConf["opengoldbox"]
        for _, tItem in pairs(tData.tItemIDList) do
            for _, tHearsayCond in pairs(tConf.tParam) do
                if tItem.nItemID == tHearsayCond[1] then
                    local sCont = string.format(tConf.sHearsay, sRoleName, ctPropConf[nItemID].sName)
                    GF.SendHearsayMsg(sCont)
                end
            end
        end
    end
end

--获得宠物
function CEventHandler:OnGotPet(oRole, tData)
    if tData and tData.bIsHearsay then
        local sRoleName = oRole:GetName()
        local tConf = ctHearsayConf["gotpet"]
        local bCanHearsay = false
        for _, tCond in pairs(tConf.tParam) do
            if tCond[1] == tData.nType then
                bCanHearsay = true
            end
        end
        if bCanHearsay then
            local sCont = string.format(tConf.sHearsay, sRoleName, ctPetInfoConf[tData.nPetID].sName)
            GF.SendHearsayMsg(sCont)
        end

    end
end

--竞技场获胜
function CEventHandler:OnArenaWin(oRole, tData)
    if tData and tData.bIsHearsay then
        local sRoleName = oRole:GetName()
        local tConf = ctHearsayConf["arenakeepwin"]
        assert(tConf, "没有传闻配置")
        local bCanHearsay = false
        for _, tCond in pairs(tConf.tParam) do
            if tData.nKeepTimes == tCond[1] then
                bCanHearsay = true
            end
        end
        if bCanHearsay then
            local sCont = string.format(tConf.sHearsay, sRoleName)
            GF.SendHearsayMsg(sCont)
        end
    end
end

--完成一次心魔侵蚀
function CEventHandler:OnCompXinMoQinShi(oRole, tData)
    if tData and tData.bIsHearsay then
        local sRoleName = oRole:GetName()

        --心魔掉落传闻
        local tHearsayConf = ctHearsayConf["fbxinmodrop"]
        assert(tHearsayConf, "没有传闻配置")
        tData.tItemIDList = tData.tItemIDList or {}
        if next(tData.tItemIDList) then
            for _, tItem in pairs(tData.tItemIDList) do
                for _, tHearsayCond in pairs(tHearsayConf.tParam) do
                    if tItem[1] == tHearsayCond[1] then
                        local sCont = string.format(tHearsayConf.sHearsay, sRoleName, ctPropConf[tItem[1]].sName)
                        GF.SendHearsayMsg(sCont)
                    end
                end
            end
        end

        --挑战较高星心魔传闻
        local tChalHearsayConf = ctHearsayConf["chalxinmo"]
        if tData.nStar >= tChalHearsayConf.tParam[1][1] then
            local sCont = string.format(tChalHearsayConf.sHearsay, sRoleName, tData.nStar)
            GF.SendHearsayMsg(sCont)
        end
    end
end

--完成神兽乐园
function CEventHandler:OnCompShenShouLeYuan(oRole, tData)
    if tData and tData.bIsHearsay then
        local sRoleName = oRole:GetName()
        local tHearsayConf = ctHearsayConf["fbshenshoudrop"]
        assert(tHearsayConf, "没有传闻配置")
        tData.tItemIDList = tData.tItemIDList or {}
        if not next(tData.tItemIDList) then return end
        for _, tItem in pairs(tData.tItemIDList) do
            for _, tHearsayCond in pairs(tHearsayConf.tParam) do
                if tItem[1] == tHearsayCond[1] then
                    local sCont = string.format(tHearsayConf.sHearsay, sRoleName, ctPropConf[tItem[1]].sName)
                    GF.SendHearsayMsg(sCont)
                end
            end
        end
    end
end

--完成决战九霄
function CEventHandler:OnCompJueZhanJiuXiao(oRole, tData)
    if tData and tData.bIsHearsay then
        local sRoleName = oRole:GetName()
        local tHearsayConf = ctHearsayConf["fbjuezhandrop"]
        assert(tHearsayConf, "没有传闻配置")
        assert(tData.nItemID, "传闻物品ID错误")
        for _, tHearsayCond in pairs(tHearsayConf.tParam) do
            if tData.nItemID == tHearsayCond[1] then
                local sCont = string.format(tHearsayConf.sHearsay, sRoleName, ctPropConf[tData.nItemID].sName)
                GF.SendHearsayMsg(sCont)
            end
        end
    end
end

--完成混沌试炼
function CEventHandler:OnCompHunDunShiLian(oRole, tData)
    if tData and tData.bIsHearsay then
        local sRoleName = oRole:GetName()
        local tHearsayConf = ctHearsayConf["fbhundundrop"]
        assert(tHearsayConf, "没有传闻配置")
        assert(tData.nItemID, "传闻物品ID错误")
        for _, tHearsayCond in pairs(tHearsayConf.tParam) do
            if tData.nItemID == tHearsayCond[1] then
                local sCont = string.format(tHearsayConf.sHearsay, sRoleName, ctPropConf[tData.nItemID].sName)
                GF.SendHearsayMsg(sCont)
            end
        end
    end
end

--仙侣升星
function CEventHandler:OnPartnerUpStar(oRole, tData)
    oRole.m_oTargetTask:OnEventHandler(gtTargetTask.ePartnerUpStar, 1, true)
    oRole.m_oGuideTask:OnEventHandler(gtGuideTask.ePartnerUpStar, 1, true)
end

--宝石镶嵌
function CEventHandler:OnGem(oRole, tData)
    --每镶嵌一次遍历统计一次
    oRole.m_oTargetTask:OnEventHandler(gtTargetTask.eGem, tData.tLevelMap, false)
end

--装备法宝
function CEventHandler:OnEquFaBao(oRole, tData)
    oRole.m_oTargetTask:OnEventHandler(gtTargetTask.eEquFaBao, tData.tFaBaoLevelCountMap, false)
end

--辅助技能升级
function CEventHandler:OnAssistedSkillUpLevel(oRole, tData)
    local tSkillLevelMap = oRole.m_oTargetTask:GetCurrTargetData(gtTargetTask.eAssistedSkillUpLevel) or {}
    local nOldNum = tSkillLevelMap[tData.nLevel] or 0
    tSkillLevelMap[tData.nLevel] = nOldNum + 1
    oRole.m_oTargetTask:OnEventHandler(gtTargetTask.eAssistedSkillUpLevel, tSkillLevelMap, false)
end

--器灵升级
function CEventHandler:OnQiLingUpLevel(oRole, tData)
    oRole.m_oTargetTask:OnEventHandler(gtTargetTask.eQiLingUpLevel, tData.nQiLingLevel, false)
end

--宠物合成
function CEventHandler:OnPetCompose(oRole, tData)
    oRole.m_oTargetTask:OnEventHandler(gtTargetTask.ePetCompose, 1, true)
    oRole.m_oGuideTask:OnEventHandler(gtGuideTask.ePetCompose, 1, true)
    if tData and tData.bIsHearsay then
        local sRoleName = oRole:GetName()
        local tHearsayConf = ctHearsayConf["petcompose"]
        assert(tHearsayConf, "没有传闻配置")
        for _, tHearsayCond in pairs(tHearsayConf.tParam) do
            if tData.nSkillNum >= tHearsayCond[1] then
                local sCont = string.format(tHearsayConf.sHearsay, sRoleName, tData.nSkillNum)
                GF.SendHearsayMsg(sCont)
                break
            end
        end
    end
end

--宠物炼骨
function CEventHandler:OnPetLianGu(oRole, tData)
    oRole.m_oTargetTask:OnEventHandler(gtTargetTask.ePetLianGu, 1, true)
    oRole.m_oGuideTask:OnEventHandler(gtGuideTask.ePetLianGu, 1, true)
end

--法宝合成
function CEventHandler:OnFaBaoCompose(oRole, tData)
    oRole.m_oTargetTask:OnEventHandler(gtTargetTask.eFaBaoCompose, 1, true)
    oRole.m_oGuideTask:OnEventHandler(gtGuideTask.eFaBaoCompose, 1, true)
end

--器灵升阶
function CEventHandler:OnQiLingUpGrade(oRole, tData)
    oRole.m_oTargetTask:OnEventHandler(gtTargetTask.eQiLingUpGrade, tData.nQiLingGrade, false)
end

--完成支线任务
function CEventHandler:OnCompBranchTask(oRole, tData)
    oRole.m_oTargetTask:OnEventHandler(gtTargetTask.eAchieveBranchTask, tData.nTaskID, false)
end

--伙伴学习
function CEventHandler:OnPartnerLearn(oRole, tData)
    oRole.m_oTargetTask:OnEventHandler(gtTargetTask.ePartnerLearn, 1, true)
end

--综合战斗力
function CEventHandler:OneColligatePowerChange(oRole, tData)
    oRole.m_oTargetTask:OnEventHandler(gtTargetTask.eColligatePower, tData.nColligatePower, false)
end

--完成神魔志
function CEventHandler:OnCompShenMoZhi(oRole, tData)
    local tPassMap = oRole.m_oTargetTask:GetCurrTargetData(gtTargetTask.eCompShenMoZhi) or {}
    local sRoleName = oRole:GetName()
    local nCurrPass = 0
    if type(tPassMap) == "number" then
        --数据兼容处理
        nCurrPass = tPassMap
        local tConf = ctShenMoZhiConf[nCurrPass]
        if tData.nType == tConf.nType then
            --如果保存的关卡类型和刚刚打完的一致
            if nCurrPass > tData.tPassMap[tData.nType] then
                tData.tPassMap[tData.nType] = nCurrPass
            end
            oRole.m_oTargetTask:OnEventHandler(gtTargetTask.eCompShenMoZhi, tData.tPassMap, false)            
        else
            --如果保存的关卡类型和刚刚打完的不一致，两种数据都要保存
            tData.tPassMap[tConf.nType] = nCurrPass
            oRole.m_oTargetTask:OnEventHandler(gtTargetTask.eCompShenMoZhi, tData.tPassMap, false)
        end
    else
        nCurrPass = tPassMap[tData.nType] or 0
        if nCurrPass < tData.tPassMap[tData.nType] then
            oRole.m_oTargetTask:OnEventHandler(gtTargetTask.eCompShenMoZhi, tData.tPassMap, false)
        end
    end

    if tData and tData.bIsHearsay then
        local tFBShenMoConf = ctHearsayConf["fbshenmozhi"]
        if tData.nStar >= tFBShenMoConf.tParam[1][1] then
            local sStr = ""
            if tData.nType == 1 then
                sStr = "普通"
            elseif tData.nType == 2 then
                sStr = "精英"
            else
                sStr = "英雄"
            end
            local sCont = string.format(tFBShenMoConf.sHearsay, sRoleName, sStr, tData.nChapter)
            GF.SendHearsayMsg(sCont)
        end
    end
end

--完成妖兽突袭
function CEventHandler:OnCompYaoShouTuXi(oRole, tData)
    oRole.m_oTargetTask:OnEventHandler(gtTargetTask.eCompYaoShouTuXi, 1, true)
    local sRoleName = oRole:GetName()
    if tData and tData.bIsHearsay then
        --挑战较高星数妖兽传闻
        local tChalHearsayConf = ctHearsayConf["chalyaoshou"]
        if tData.nStar >= tChalHearsayConf.tParam[1][1] then
            local sCont = string.format(tChalHearsayConf.sHearsay, sRoleName, tData.nStar)
            GF.SendHearsayMsg(sCont)
        end
    end
end

--添加好友次数(只统计主动发出的申请次数)
function CEventHandler:OnAddFriend(oRole, tData)
    oRole.m_oTargetTask:OnEventHandler(gtTargetTask.eAddFriendCount, 1, true)
end

--发布结婚邀请信息次数
function CEventHandler:OnMarryInvite(oRole, tData)
    oRole.m_oTargetTask:OnEventHandler(gtTargetTask.eInviteMarryCount, 1, true)
    oRole.m_oGuideTask:OnEventHandler(gtGuideTask.eInviteMarryCount, 1, true)
end

--法阵升级
function CEventHandler:OnFaZhenUpLevel(oRole, tData)
    local tFaZhenLevelMap = oRole.m_oTargetTask:GetCurrTargetData(gtTargetTask.eFaZhenLevel) or {} 
    for nLevel, nNum in pairs(tData.tLevelMap) do
        tFaZhenLevelMap[nLevel] = (tFaZhenLevelMap[nLevel] or 0) + nNum
    end
    oRole.m_oTargetTask:OnEventHandler(gtTargetTask.eFaZhenLevel, tFaZhenLevelMap, false)
end
--累计进入挂机场景次数
function CEventHandler:OnEnterGuaJiDup(oRole, tData)
    oRole.m_oTargetTask:OnEventHandler(gtTargetTask.eEnterGuaJiDup, 1, true)
end

--挑战挂机关卡至第X关
function CEventHandler:ChalGuaJiGuanQia(oRole, tData)
    oRole.m_oTargetTask:OnEventHandler(gtTargetTask.eChalGuaJiGuanQia, tData.nGuanQia, false) 
end

--点击挑战挂机boss事件(点击事件)
function CEventHandler:ClickChalGuaJiBoss(oRole, tData)
    oRole.m_oTargetTask:OnEventHandler(gtTargetTask.eClickChalGuaJiBoss, 1, true)
end

--点击自动挑战挂机boss事件(点击事件)
function CEventHandler:ClickAutoChalGuaJiBoss(oRole, tData)
    oRole.m_oTargetTask:OnEventHandler(gtTargetTask.eClickAutoChalBoss, 1, true)    
end

function CEventHandler:OnEquipEquipment(oRole, tData)
    oRole.m_oTargetTask:OnEventHandler(gtTargetTask.eEquipEquipment, tData.tLevelMap, false)
end

function CEventHandler:OnCompAllTargetTask(oRole, tData)
    oRole.m_oTargetTask:OnEventHandler(gtTargetTask.eCompAllTargetTask, tData.nTargetTaskID, false)
end

function CEventHandler:OnPetUpGrade(oRole, tData)
    if tData and tData.bIsHearsay then
        --挑战较高星数妖兽传闻
        local sRoleName = oRole:GetName()
        local tUpGradeHearsayConf = ctHearsayConf["petupgrade"]
        if tData.nGrade >= tUpGradeHearsayConf.tParam[1][1] then
            local sCont = string.format(tUpGradeHearsayConf.sHearsay, sRoleName, tData.sPetName, tData.nGrade)
            GF.SendHearsayMsg(sCont)
        end
    end
end
--加入帮派
function CEventHandler:OnJoinUnion(oRole, tData)
    oRole.m_oGuideTask:OnEventHandler(gtGuideTask.eJoinUnion, 1, true)
end

--摆摊道具上架
function CEventHandler:OnMarketItemOnSale(oRole, tData)
    oRole.m_oGuideTask:OnEventHandler(gtGuideTask.eMarketItemOnSale, 1, true)
end

--商会出售东西
function CEventHandler:OnChamberCoreItemOnSale(oRole, tData)
    oRole.m_oGuideTask:OnEventHandler(gtGuideTask.eChamberCoreItemOnSale, 1, true)
end