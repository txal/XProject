--需要后台定制配置表的功能

--类型
gtBackstageType = 
{
	eFristRecharge = 11, 		--首充
	eAccumulativeRecharge = 12, --累充
	eCards = 13, 	--月卡
	eSingleRecharge = 14,		--单次充值
	eDayRecharge = 15,			--累天充值
	eResumeYB = 16,				--累积消耗元宝
	eAllFirstRecharge = 17,		--全服首充团购
}

--定义
gtBackstageDef = 
{
	[gtBackstageType.eFristRecharge] = {sName="新服首充", sConf="ctRechargeEtcConf"},  --首充	
	[gtBackstageType.eAccumulativeRecharge] = {sName="累充", sConf="ctLCConf"}, --累充
	[gtBackstageType.eCards] = {sName="月卡/周卡", sConf="ctCardConf"}, --月卡/周卡
	[gtBackstageType.eSingleRecharge] = {sName="单笔充值",sConf="ctSCConf"},	--单次充值
	[gtBackstageType.eDayRecharge] = {sName="累天充值",sConf="ctDCConf"},		--累天充值
	[gtBackstageType.eResumeYB] = {sName="累积消耗元宝",sConf="ctLYConf"},			--累积消耗元宝
	[gtBackstageType.eAllFirstRecharge] = {sName="全服首充团购",sConf="ctTCConf"}	--全服首充团购
}

