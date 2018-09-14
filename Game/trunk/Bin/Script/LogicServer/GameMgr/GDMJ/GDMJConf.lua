gtGDMJConf = 
{
	--房间类型
	tRoomType = 
	{
		eRoom1 = 1,		--广东麻将熟人房
		eRoom2 = 2,		--广东麻将自由房
	},

	--麻将牌
	tMJs = 
	{
		0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09,				--万
		0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19,				--饼
		0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29,				--条
		0x31, 0x32, 0x33, 0x34,												--风
		0x41, 0x42, 0x43,													--字
		0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09,				--万
		0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19,				--饼
		0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29,				--条
		0x31, 0x32, 0x33, 0x34,												--风
		0x41, 0x42, 0x43,													--字
		0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09,				--万
		0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19,				--饼
		0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29,				--条
		0x31, 0x32, 0x33, 0x34,												--风
		0x41, 0x42, 0x43,													--字
		0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09,				--万
		0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19,				--饼
		0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29,				--条
		0x31, 0x32, 0x33, 0x34,												--风
		0x41, 0x42, 0x43													--字	
	},

	--风位
	tFengWei =
	{
		eEast = 1,		--东
		eSouth = 2,		--南
		eWest = 3,		--西
		eNorth = 4, 	--北
	},

	--杂项常量
	tEtc = 
	{
		nMaxHandMJ = 14,	--玩家最大拥牌数
		nMJMaskValue = 0x0F,--麻将数值掩码
		nMJMaskType = 0xF0,	--麻将类型掩码
		nMaxPlayer = 4,		--最多人数
	},

	--九连灯值(万/饼/条)
	tNineLight = {1, 1, 1, 2, 3, 4, 5, 6, 7, 8, 9, 9, 9},

	--十三幺牌
	tThirteen = {0x01, 0x09, 0x11, 0x19, 0x21, 0x29, 0x31, 0x32, 0x33, 0x34, 0x41, 0x42, 0x43},

	--麻将类型结构
	tBlockStyle = 
	{	
		eNone = 0,			--无
		eChi = 1,			--吃牌结构,2个与上家出的牌可形成顺子
		eSun = 2,	 		--顺子结构,3个同花,有序
		ePeng = 3,	 		--碰子结构,3个相同	
		eKe = 4,			--刻子结构,3个相同,非碰
		eGang = 5,			--杠子结构,4个相同
		eAnGang = 6,		--暗杠结构,4个相同,自摸
		eZMGang = 7,		--补杠/放名杠,4个相同
	},

	--麻将块结构
	tMJBlock = 
	{
		nFirst = 0,						--麻将块第一张牌值
		nStyle = 0,						--麻将块类型
		nSetp = 0,						--第几步操作
		nTarget = 0,					--目标ID(杠碰吃的目标)
	},
	NewMJBlock = function(self)
		return table.DeepCopy(self.tMJBlock)
	end,

	--胡牌结构
	tMJHu = 
	{
		tBlock = {},			--麻将块
		nJiangMJ = 0,			--将牌
		bQiangGang = false, 	--抢杠胡
	},
	NewMJHu = function(self)
		return table.DeepCopy(self.tMJHu)
	end,

	--杠牌类型
	tGangType = 
	{
		eNormal = 1,	--普通杠
		eZMGang = 2,	--自摸杠/补杠
		eAnGang = 4,	--暗杠
	},

	--杠牌
	tMJGang = 
	{
		nGangMJ = 0,				--所杠的牌
		nGangStyle = 0,				--杠牌类型:4-暗杠,2-摸明杠/补杠,1-普通杠,0-无杠
	},
	NewMJGang = function(self)
		return table.DeepCopy(self.tMJGang)
	end,

	--操作
	tMJAction = 
	{
		eNone = 0,
		eChi = 1,	--吃
		ePeng = 2,	--碰
		eGang = 3,	--杠
		eHu	= 4,	--胡
	},

	--胡牌类型
	tHuType = 
	{
		eNone = 0,
		eNormal = 1,		--普通胡
		eFourGhost = 2,		--4鬼
		eSevenPair = 3,		--7对
		ePengPeng = 4,		--碰碰胡
		eQingYiSe = 5,		--清一色
		eQuanFeng = 6,		--全风
		eThirteen = 7,		--十三幺
		eYaoJiu = 8,		--幺九
	},

	--鬼牌类型
	tGhostType = 
	{
		eNone = 1,			--无鬼
		eBlank = 2,			--白板鬼
		eOpen = 3,			--翻鬼
	},

	--马牌类型
	tMaType = 
	{
		eNone = 1,		--无马
		eTwo = 2,		--2马	
		eFour = 3,		--4马
		eSix = 4,		--6马
		eZhuang = 5,	--连庄买马
	},

	--选项
	tMJOption = 
	{
		nRound = 8, 					--局数(8|16)
		bWuFeng = true, 				--无风
		bGenZhuang = true,				--跟庄
		bGangShangBao = false, 			--杠上开花全包
		bGangShangDouble = false,		--杠上开花2倍
		bQiangGang = false, 			--可抢杠胡
		bQiangGangBao = false, 			--抢杠胡全包
		bQiangGangDouble = false, 		--抢杠胡2倍
		bSiGui = false, 				--4鬼胡牌
		bSiGuiDouble = false,			--4鬼胡牌2倍
		bQiDui = true,					--7对胡4倍
		bPengPeng = true,				--碰碰胡2倍
		bQingYiSe = true,				--清一色4倍
		bQuanFeng = true,				--全风8倍
		bShiSanYao = true,				--十三幺8倍
		bYaoJiu = true,					--幺九6倍
		nGhostType = 1, 				--鬼牌类型
		bDoubleGhost = false, 			--双鬼
		bGhostDouble = false,			--无鬼双倍
		nMaType = 5,					--连庄买马
	},
	NewMJOption = function(self)
		return table.DeepCopy(self.tMJOption)
	end,

	--马牌关联
	tMaMap = 
	{
		[1] = {0x01, 0x05, 0x09, 0x11, 0x15, 0x19, 0x21, 0x25, 0x29, 0x31, 0x41}, --庄家
		[2] = {0x02, 0x06, 0x12, 0x16, 0x22, 0x26, 0x32, 0x42}, --下家
		[3] = {0x03, 0x07, 0x13, 0x17, 0x23, 0x27, 0x33, 0x43},	--对家
		[4] = {0x04, 0x08, 0x18, 0x18, 0x28, 0x28, 0x34}, --上家
	},
}