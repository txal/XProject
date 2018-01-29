--常量
nMAX_INTEGER = 0x4000000000000	--最大整数(100兆)
nSERVICE_SHIFT = 24				--会话ID中的服务ID移位
nMAX_NAMELEN = 128				--名字长度--玩家状态

--玩家状态
gtUserState = 
{
 	eNormal = 0, 	--正常
 	eJinYan = 1, 	--禁言
 	eFengHao = 2, 	--封号
}