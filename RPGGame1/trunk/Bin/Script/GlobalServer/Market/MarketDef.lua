


gnMarketStallGridNumDefalut = 8       --初始默认的摊位格子
gnMarketStallGridNumUnlockMax = 10    --最大解锁格子数量
--gnMarketStallGridNumMax = 18
gnMarketPrivateKeyMax = 0x7fffffff
gnMarketGlobalKeyMax = 0x7fffffff
gnMarketGKeyBegin = 100000              --玩家出售道具，起始GKey

gnMarketItemActiveTime = (16 * 60 * 60)   --上架时间
gnMarketPageFlushTime = (5 * 60)     --玩家道具购买页表刷新间隔
--gnMarketDelItemCacheTime = (10 * 60 * 60) --待清理物品的缓存时间，必须大于等于gnMarketPageFlushTime
gnMarketPageViewNum = 8    --每个页表刷新显示物品数量

gnMarketStallSaveInterval = (60 * 5)           --玩家摊位脏数据保存间隔


gtMarketItemState = 
{
	eSelling = 1,      --上架销售中
	eSoldOut = 2,      --已售罄
	eRemove = 3,       --已下架
}

--[[
gtMarketItemRemoveType = 
{
	eExpiry = 1,       --逾期下架
	eRemove = 2,       --主动下架
	eGM = 3,           --GM下架
}
]]

gtMarketFrobidReason = 
{
	eTradeFreq = 1,      --短时间交易频繁
	eDataException = 2,  --数据异常
	eGM = 3,             --GM禁止
}

