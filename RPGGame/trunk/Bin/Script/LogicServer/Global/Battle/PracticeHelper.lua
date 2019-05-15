--修炼辅助类
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--构造函数
function CPracticeHelper:Ctor()
end

--根据单位类型取攻法修炼ID
function CPracticeHelper:GetAtkPraID(oUnit)
	local nObjType = oUnit:GetObjType()
	--人物/怪物
	if nObjType == gtObjType.eRole or nObjTYpe == gtObjType.eMonster then
		return 101
	end
	--伙伴
	if nObjType == gtObjType.ePartner then
		return 201
	end
	--宠物
	if nObjType == gtObjType.ePet then
		return 301
	end
	return 0
end

--根据单位类型取防御修炼ID
--@nAtkType 攻击类型(1物理, 2法术)
function CPracticeHelper:GetDefPraID(oUnit, nAtkType)
	local nObjType = oUnit:GetObjType()
	--人物/怪物
	if nObjType == gtObjType.eRole or nObjTYpe == gtObjType.eMonster then
		return (nAtkType==1) and 102 or 103
	end
	--伙伴
	if nObjType == gtObjType.ePartner then
		return (nAtkType==1) and 202 or 203
	end
	--宠物
	if nObjType == gtObjType.ePet then
		return 302
	end
	return 0
end

--物理攻击修炼加成
function CPracticeHelper:PhyAtkPraAdd(oUnit, oTarUnit)
	local tSrcPraMap = oUnit:GetPracticeMap()
	local tTarPraMap = oTarUnit:GetPracticeMap()

	local nAtkPraID = self:GetAtkPraID(oUnit)
	local nDefPraID = self:GetDefPraID(oTarUnit)

	local nSrcPraLv = tSrcPraMap[nAtkPraID] or 0
	local nTarPraLv = tTarPraMap[nDefPraID] or 0

	local nPerAdd = math.max(0, (nSrcPraLv-nTarPraLv)*0.02)
	local nValAdd = math.max(0, (nSrcPraLv-nTarPraLv)*5)
	return nPerAdd, nValAdd
end

--法术攻击修炼加成
function CPracticeHelper:MagAtkPraAdd(oUnit, oTarUnit)
	local tSrcPraMap = oUnit:GetPracticeMap()
	local tTarPraMap = oTarUnit:GetPracticeMap()

	local nAtkPraID = self:GetAtkPraID(oUnit)
	local nDefPraID = self:GetDefPraID(oTarUnit)

	local nSrcPraLv = tSrcPraMap[nAtkPraID] or 0
	local nTarPraLv = tTarPraMap[nDefPraID] or 0

	local nPerAdd = math.max(0, (nSrcPraLv-nTarPraLv)*0.02)
	local nValAdd = math.max(0, (nSrcPraLv-nTarPraLv)*5)
	return nPerAdd, nValAdd
end

--根据单位类型取封印加成
function CPracticeHelper:MagSealPraAdd(oUnit)
	local nObjType = oUnit:GetObjType()
	local tPraMap = oUnit:GetPracticeMap()

	--人物/怪物
	if nObjType == gtObjType.eRole or nObjTYpe == gtObjType.eMonster then
		return (tPraMap[101] or 0)*2
	end
	--伙伴
	if nObjType == gtObjType.ePartner then
		return (tPraMap[201] or 0)*2
	end
	return 0
end

--根据单位类型取抗印加成
function CPracticeHelper:MagAntiSealPraAdd(oUnit)
	local nObjType = oUnit:GetObjType()
	local tPraMap = oUnit:GetPracticeMap()

	--人物/怪物
	if nObjType == gtObjType.eRole or nObjTYpe == gtObjType.eMonster then
		return (tPraMap[103] or 0)*2
	end
	--伙伴
	if nObjType == gtObjType.ePartner then
		return (tPraMap[203] or 0)*2
	end
	return 0
end
