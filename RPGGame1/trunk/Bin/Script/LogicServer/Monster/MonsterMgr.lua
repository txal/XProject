--怪物管理器
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CMonsterMgr:Ctor()
	self.m_tMonsterMap = {}
	self.m_nAutoID = 0
end

function CMonsterMgr:GenID()
	local nMonsterID = nil
    for k = 1, 500 do --最多尝试500次
        self.m_nAutoID = math.max(self.m_nAutoID % 0x7FFFFFFF, 0X70000000) + 1
        if not self.m_tMonsterMap[self.m_nAutoID] then --当前已存在，还未销毁
			nMonsterID = self.m_nAutoID
			break
        end
    end
	return nMonsterID
end

function CMonsterMgr:GetMonster(nObjID)
	return self.m_tMonsterMap[nObjID]
end

--这个函数只给测试用,游戏中不能调用!!
function CMonsterMgr:GetMonsterByConfID(nConfID)
	for _, oMonster in pairs(self.m_tMonsterMap) do
		if oMonster:GetConfID() == nConfID then
			return oMonster
		end
	end
end

function CMonsterMgr:GetCount()
	local nCount = 0
	for nObjID, oMonster in pairs(self.m_tMonsterMap) do
		nCount = nCount + 1
	end
	return nCount
end

--创建普通怪物
--@nConfID 怪物配置ID
--@nDupMixID 副本唯一ID
--@nPosX 坐标
function CMonsterMgr:CreateMonster(nConfID, nDupMixID, nPosX, nPosY)
	local cMonClass = gtMonClass[gtMonType.eNormal]

	local nID = self:GenID()
	local oMonster = cMonClass:new(nID, nConfID)
	self.m_tMonsterMap[nID] = oMonster

	local oDup = goDupMgr:GetDup(nDupMixID)
	if not oDup then
		return LuaTrace("副本不存在", nDupMixID)
	end
	local tDupConf = oDup:GetConf()
	oMonster:EnterScene(nDupMixID, nPosX, nPosY, 0, tDupConf.nFace)

	return oMonster
end

--创建公共NPC,不主动进入场景
function CMonsterMgr:CreatePublicNpc(nNpcType, nConfID, nDupMixID)
	local cNpcClass = gtMonClass[nNpcType]
	assert(cNpcClass, "参数错误，不存在的NPC类型")

	local nID = self:GenID()
	local oMonster = cNpcClass:new(nID, nConfID)
	self.m_tMonsterMap[nID] = oMonster
	return oMonster
end

--创建公共NPC并进入场景
function CMonsterMgr:CreatePublicNpcWithEnter(nNpcType, nConfID, nDupMixID, nPosX, nPosY, nFace)
	local cNpcClass = gtMonClass[nNpcType]
	assert(cNpcClass, "参数错误，不存在的NPC类型")

	local nID = self:GenID()
	local oMonster = cNpcClass:new(nID, nConfID)
	self.m_tMonsterMap[nID] = oMonster

	local oDup = goDupMgr:GetDup(nDupMixID)
	if not oDup then
		return LuaTrace("副本不存在", nDupMixID)
	end
	local tDupConf = oDup:GetConf()
	nFace = nFace or tDupConf.nFace
	oMonster:EnterScene(nDupMixID, nPosX, nPosY, 0, nFace)

	return oMonster
end

--创建任务怪物
--@nTaskType 任务类型
--@nConfID 任务配置ID
function CMonsterMgr:CreateTaskMonster(nTaskType, nConfID)
	local cMonClass = gtMonClass[gtMonType.eTaskNpc]

	local nID = self:GenID()
	local oMonster = cMonClass:new(nID, nTaskType, nConfID)
	self.m_tMonsterMap[nID] = oMonster
	return oMonster
end

--创建不可见的战斗怪物
function CMonsterMgr:CreateInvisibleMonster(nConfID)
	local cMonClass = gtMonClass[gtMonType.eInvisible]

	local nID = self:GenID()
	local oMonster = cMonClass:new(nID, nConfID)
	self.m_tMonsterMap[nID] = oMonster
	return oMonster
end

--创建只配置怪物组产生的战斗怪物
function CMonsterMgr:CreateMonsterByGroup(nConfID, tModuleConf)
	local cMonClass = gtMonClass[gtMonType.eCreateByGroup]

	local nID = self:GenID()
	local oMonster = cMonClass:new(nID, nConfID, tModuleConf)
	self.m_tMonsterMap[nID] = oMonster
	return oMonster
end

--移除
function CMonsterMgr:RemoveMonster(nObjID)
	local oMonster = self:GetMonster(nObjID)
	if oMonster then
		oMonster:Release()
	end
	self.m_tMonsterMap[nObjID] = nil
end

--清理
function CMonsterMgr:OnMonsterCollected(nObjID)
	local oMonster = self:GetMonster(nObjID)
	if oMonster then
		LuaTrace("怪物被收集(CPP)***", oMonster:GetConf())
	end
	self:RemoveMonster(nObjID)
end

function CMonsterMgr:GMDumpMonster()
    local nCount = 0;
    for k, v in pairs(self.m_tMonsterMap) do
        nCount = nCount + 1 
        local oDup = v:GetDupObj()
        if oDup then
            LuaTrace(v:GetConfID(), v:GetName(), oDup:GetDupID())
        else
            LuaTrace(v:GetConfID(), v:GetName(), v:GetAOIID(), v:GetDupMixID())                                                                                                                                                                    
        end 
    end 
    LuaTrace("怪物数量***", nCount)
end

function CMonsterMgr:FixLeakScene()
    for k, v in pairs(self.m_tMonsterMap) do                                                                                                   
        local oDup = v:GetDupObj()
        if not oDup then 
            if v:GetAOIID() > 0 and v:GetNativeObj() and v:GetDupMixID() > 0  then 
                local nDupMixID = v:GetDupMixID()
                local oNative = goNativeDupMgr:GetDup(nDupMixID)
                if oNative then
                	local tList = oNative:GetObjList(-1, gtGDef.tObjType.eRole)
                	if #tList == 0 then
                		goNativeDupMgr:RemoveDup(nDupMixID)
		            end
                end
            end  
        end
    end
end
