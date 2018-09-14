--事件
gtEvent = 
{
	eLogin = 1, 		--登陆
	eLogout = 2,		--离线
	eAddItem = 3, 		--加物品
	eSubItem = 4, 		--减物品
	eSendMail = 5,		--发送邮件
	eSwitchLogic = 6,	--切换逻辑服
}

--原因
gtReason =
{
	eNone = 0,					--无条件(GM)
	eRecharge = 1, 				--充值
	eFreeRoomCalc = 2, 			--自由房结算
	eFreeRoomExchange = 3,		--自由房兑换体力
	eFreeRoomWinCntAward = 4, 	--自由房连胜奖励
	eFreeRoomRoundAward = 5, 	--自由房对局奖励
	eGDMJRoundEnd = 6,			--广东麻将1局结束
}
