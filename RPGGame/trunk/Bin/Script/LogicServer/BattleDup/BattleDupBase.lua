--副本基类
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert


function CBattleDupBase:Ctor(nID, nGameType)
    assert(nID and nGameType)
    self.m_nID = nID
    self.m_nGameType = nGameType

    self.m_tSceneList = {}  --{nIndex:nDupMixID, ...}
    local tBattleDupConf = ctBattleDupConf[self.m_nGameType]
    assert(tBattleDupConf, "错误的副本类型")
    local tConfDupList = tBattleDupConf.tDupList
    for k, v in ipairs(tBattleDupConf.tDupList) do 
        local nDupConfID = v[1]
        local oScene = goDupMgr:CreateDup(nDupConfID) 
        if not oScene then 
            self:OnRelease() --释放下已经创建的资源
            assert(oScene, "创建场景失败")
        end
        oScene:SetAutoCollected(false)
        table.insert(self.m_tSceneList, oScene:GetMixID())
    end

    self.m_tRoleMap = GF.WeakTable("kv")    --{nRoleID:oRole, ...}进入场景加入，离开场景删除
    self.m_tDupRoleMap = GF.WeakTable("kv") --{nRoleID:oRole, ...}发起战斗的玩家，必须属于m_tDupRoleMap
    -- 之所以用2个map，为了区分战斗过程中，有队员离队，然后加入或创建其他队伍，
    -- 然后对本副本中的怪物发起战斗的问题
    -- 如果当前做区分，还会附带引发另外一种情况，比如，队员暂离期间进入其他副本，
    -- 然后过程中，该队员离开队伍，也会导致该队员被判定不能参与该副本玩法
    -- 如果DupRoleMap中, 没其他队员, 即这个副本，本身当前只有这一个玩家在此副本, 
    -- 没其他玩家进入, 或者其他玩家已经离开, 不将角色从DupRoleMap中移除

    self.m_tMonsterMap = GF.WeakTable("kv")  --{nMonsterID:oMonster, ...}

    --副本初始，设置为默认超时释放
    self.m_bPreRelease = true 
    self.m_nPreReleaseStamp = os.time()

    self:Init()
end

function CBattleDupBase:GetID() return self.m_nID end 
function CBattleDupBase:GetGameType() return self.m_nGameType end  --建议外层重写，指定类型
function CBattleDupBase:SetPreRelease(bRelease)   --设置副本预清理状态
    self.m_bPreRelease = bRelease and true or false 
    self.m_nPreReleaseStamp = os.time()
end

function CBattleDupBase:Init()
    --do something, init monster etc.
end

function CBattleDupBase:RegSceneCallback() 
    for k, nSceneID in pairs(self.m_tSceneList) do 
        local oScene = goDupMgr:GetDup(nSceneID)
        assert(oScene)
        oScene:RegObjEnterCallback(function (oObj, bReconnect)
            self:OnObjEnter(oObj, bReconnect)
        end)
        oScene:RegObjAfterEnterCallback(function (oObj)
            self:AfterObjEnter(oObj)
        end)
        oScene:RegObjLeaveCallback(function (oObj, nBattleID)
            self:OnObjLeave(oObj, nBattleID)
        end)
        oScene:RegObjDisconnectCallback(function (oObj)
            self:OnObjDisconnect(oObj)
        end)
        oScene:RegObjBattleBeginCallback(function (oObj)
            self:OnBattleBegin(oObj)
        end)
        oScene:RegBattleEndCallback(function (oObj, tBTRes, tExtData)
            self:OnBattleEnd(oObj, tBTRes, tExtData)
        end)
        oScene:RegTeamChangeCallback(function (oObj)
            self:OnRoleTeamChange(oObj)
        end)
    end
end

function CBattleDupBase:OnRelease()
    --release timer if existed
    self:KickAllRole()
    self:RemoveAllMonster()
    self:RemoveAllScene()
    -- if not self.m_bPreRelease then 
    --     self:SetPreRelease(true) 
    -- end
end

--检查玩家当前是否是这个副本的合法玩家
--对怪物发起攻击前或者其他相关副本操作时调用
function CBattleDupBase:CheckJoinDup(nRoleID)
    if self.m_tDupRoleMap[nRoleID] then 
        return true 
    end
    return false
end

--获取初始进入的场景ID
function CBattleDupBase:GetEnterDupMixID()
    return self.m_tSceneList[1]
end

function CBattleDupBase:OnRoleEnter(oRole, bReconnect)
    local nRoleID = oRole:GetID()
    self.m_tRoleMap[nRoleID] = oRole 

    if not next(self.m_tDupRoleMap) then 
        self.m_tDupRoleMap[nRoleID] = oRole 
    else
        local nTeamID = oRole:GetTeamID()
        local nPreRoleID = next(self.m_tDupRoleMap) 
        --正常都存在，如果离线，会触发LeaveDup，从self.m_tDupRoleMap移除
        --当前默认，队员只能通过跟随队长或者归队操作进入副本场景
        local oPreRoleID = goPalyerMgr:GetRoleByID(nPreRoleID)
        assert(oPreRoleID)
        if nTeamID > 0 or nTeamID == oPreRoleID:GetTeamID() then 
            self.m_tDupRoleMap[nRoleID] = oRole
        end
    end
end

function CBattleDupBase:OnMonsterEnter(oMonster)
    self.m_tMonsterMap[oMonster:GetID()] = oMonster 
end

function CBattleDupBase:OnObjEnter(oObj, bReconnect)
    --角色上线进入，需要判断，当前副本是否存在其他玩家，如果有，可能已被移除队伍 
    if oObj:GetObjType() == gtObjType.eRole then 
        self:OnRoleEnter(oObj, bReconnect)
    elseif oObj:GetObjType() == gtObjType.eMonster then 
        self:OnMonsterEnter(oObj)
    end
end

function CBattleDupBase:AfterRoleEnter(oRole)
    local nRoleID = oRole:GetID()
    if not self:CheckJoinDup(nRoleID) then 
        --移除玩家 进入了不属于该玩家的副本
        self:KickRole(nRoleID)
        return 
    else
        self:SetPreRelease(false)
    end
end

function CBattleDupBase:AfterMonsterEnter(oMonster)
    --do something
end

function CBattleDupBase:AfterObjEnter(oObj)
    if oObj:GetObjType() == gtObjType.eRole then 
        self:AfterRoleEnter(oObj)
    elseif oObj:GetObjType() == gtObjType.eMonster then 
        self:AfterMonsterEnter(oObj)
    end
end

function CBattleDupBase:OnRoleLeave(oRole) 
    local nRoleID = oRole:GetID()
    self.m_tRoleMap[nRoleID] = nil 
    self.m_tDupRoleMap[nRoleID] = nil

    if not next(self.m_tDupRoleMap) then 
        --如果所有玩家离开，则将副本打上待销毁标记
        self:SetPreRelease(true)
    end
end

function CBattleDupBase:OnMonsterLeave(oMonster)
    self.m_tMonsterMap[oMonster:GetID()] = nil 
end

function CBattleDupBase:OnObjLeave(oObj) 
    if oObj:GetObjType() == gtObjType.eRole then 
        self:OnRoleLeave(oObj)
    elseif oObj:GetObjType() == gtObjType.eMonster then 
        self:OnMonsterEnter(oObj)
    end
end

function CBattleDupBase:OnRoleDisconnect(oRole)
    --do something
end

function CBattleDupBase:OnObjDisconnect(oObj)
    if oObj:GetObjType() == gtObjType.eRole then 
        self:OnRoleDisconnect(oObj)
    end
end

function CBattleDupBase:OnRoleBattleBegin(oRole) 
    --do something
end
function CBattleDupBase:OnMonsterBattleBegin(oMonster) 
    --do something
end

function CBattleDupBase:OnBattleBegin(oObj)
    if oObj:GetObjType() == gtObjType.eRole then 
        self:OnRoleBattleBegin(oObj)
    elseif oObj:GetObjType() == gtObjType.eMonster then 
        self:OnMonsterBattleBegin(oObj)
    end
end

function CBattleDupBase:OnRoleBattleEnd(oRole, tBTRes, tExtData) 
    --do something
end

--怪物被击杀，默认删除
function CBattleDupBase:OnMonsterBattleEnd(oMonster, tBTRes, tExtData) 
    if not tBTRes.bWin then 
        self:RemoveMonster(oMonster:GetID()) 
    end
end

function CBattleDupBase:OnBattleEnd(oObj, tBTRes, tExtData)
    if oObj:GetObjType() == gtObjType.eRole then 
        self:OnRoleBattleEnd(oObj, tBTRes, tExtData)
    elseif oObj:GetObjType() == gtObjType.eMonster then 
        self:OnMonsterBattleEnd(oObj, tBTRes, tExtData)
    end
end

--只针对在当前场景的玩家
function CBattleDupBase:OnRoleTeamChange(oRole)
    --TODO 重写角色队伍事件，细分离队、入队事件，队长或者暂离状态变化事件
    if oRole:GetTeamID() <= 0 then --只关心离队或者队伍ID小于0的队伍变更
        local nRoleID = oRole:GetID()
        --如果当前没有其他玩家，即此副本只有这一个玩家
        --如果该玩家离队则不处理
        local bExistOther = false 
        for k, v in pairs(self.m_tDupRoleMap) do 
            if k ~= nRoleID then 
                bExistOther = true 
                break 
            end
        end
        if bExistOther then 
            self.m_tDupRoleMap[nRoleID] = nil 
            oRole:Tips("你已离开队伍，即将被传送离开当前场景") 
            --延迟3秒踢出玩家
            goTimerMgr:Interval(3, function (nTimerID) 
                goTimerMgr:Clear(nTimerID)
                self:KickRole(nRoleID)
            end)
        end
    end
end

function CBattleDupBase:KickRole(nRoleID)
    if nRoleID <= 0 then 
        return 
    end
    if not self.m_tRoleMap[nRoleID] then --已经离开该副本了
        return 
    end
    local oRole = goPalyerMgr:GetRoleByID(nRoleID)
    if not oRole then 
        return 
    end
    oRole:EnterLastCity() 
end

function CBattleDupBase:KickAllRole()
    local tRoleList = {} --防止迭代过程中回调事件修改数据
    for nRoleID, v in pairs(self.m_tRoleMap) do 
        table.insert(tRoleList, nRoleID)
    end
    for k, nRoleID in pairs(tRoleList) do 
        self:KickRole(nRoleID)
    end
end

--主动移除怪物
function CBattleDupBase:RemoveMonster(nMonsterID)
    if not self.m_tMonsterMap[nMonsterID] then --防止错误删除其他玩法或场景怪物
        return 
    end
    goMonsterMgr:RemoveMonster(nMonsterID)
end

function CBattleDupBase:RemoveAllMonster()
    local tMonsterList = {}
    for nMonsterID, v in pairs(self.m_tMonsterMap) do 
        table.insert(tMonsterList, nMonsterID)
    end
    for k, nMonsterID in ipairs(tMonsterList) do 
        self:RemoveMonster(nMonsterID)
    end
end

function CBattleDupBase:RemoveAllScene() 
    for k, nSceneID in pairs(self.m_tSceneList) do 
        goDupMgr:RemoveDup(nSceneID)
    end
end

--进入请求
function CBattleDupBase:EnterReq(nRoleID)
    assert(false, "功能未实现")
end

--离开请求
function CBattleDupBase:LeaveReq(oRole)
    if not oRole then return end
	local nPreDupMixID = oRole:GetDupMixID()
    local nRoleID = oRole:GetID()
    if not self.m_tRoleMap[nRoleID] then 
        LuaTrace("角色已经离开了此副本???")
        return 
    end
	local fnConfirmCallback = function(tData)
		oRole = goPlayerMgr:GetRoleByID(nRoleID)
		if not oRole then return end  --回调期间，角色离开了当前逻辑服
		if tData.nSelIdx == 2 then 
			--防止玩家选择过程中，队长切换到当前逻辑服其他场景，玩家跟随离开了当前场景
			local nCurDupMixID = oRole:GetDupMixID()
			if nPreDupMixID == nCurDupMixID then 
				oRole:EnterLastCity()
			end
		end
	end
	local sTipsContent = "是否确定离开当前副本？"
	local tMsg = {sCont=sTipsContent, tOption={"取消", "确定"}, nTimeOut=15}
	goClientCall:CallWait("ConfirmRet", fnConfirmCallback, oRole, tMsg)
end


