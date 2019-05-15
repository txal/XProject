

gtAppellationType = 
{
    eNormal = 1,       --普通称号
    eTimeLimit = 2,    --限时称号
    ePVPAct = 3,       --PVP活动限时称号
    eArena = 4,        --竞技场称号
    eRelation = 5,     --玩家关系称号
    eRank = 6,         --排行榜限时称号
    eUnionPos = 7,     --帮会职务关联称号
    ePVEAct = 8,        --PVE活动限时称号
}

gtAppellationClass = 
{
    [gtAppellationType.eNormal] = CAppellationBase,
    [gtAppellationType.ePVPAct] = CAppellationPVPAct,
    [gtAppellationType.eArena] = CAppellationBase,
    [gtAppellationType.eRelation] = CAppellationRelation,
    [gtAppellationType.eUnionPos] = CAppellationUnionPos,
    [gtAppellationType.eRank] = CAppellationRank,
    [gtAppellationType.ePVEAct] = CAppellationPVEAct,
}


