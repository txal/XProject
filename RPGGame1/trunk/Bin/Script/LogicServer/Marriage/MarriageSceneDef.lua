

gtWeddingNpcState = 
{
	eNormal = 1,    --正常
	ePrepare = 2,   --申请中
	eWedding = 3,   --婚礼中
	eCandy = 4,     --喜糖发放中
}

gtPickItemType = 
{
	eCandy = 1,		--喜糖
	eOldman = 2,	--月老物品	
}

gtPickItemTips = 
{
	[gtPickItemType.eCandy] = "手太慢了，没抢到",
	[gtPickItemType.eOldman] = "该礼品已经消失",
}