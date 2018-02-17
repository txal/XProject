--事件
gtEvent = 
{
	eLogin = 1, 			--登陆(field1:上次离线时间)
	eLogout = 2,			--离线(field1:此次在线时间)
	eAddItem = 3, 			--加物品(field1:类型; field2:编号; field3:增加数量; field4:当前拥有)
	eSubItem = 4, 			--减物品(field1:类型; field2:编号; field3:扣除数量; field4:当前拥有)
	eRecharge = 5, 			--充值(field1:订单号; field2:配置号; field3:人民币; field4:元宝数; field5:双倍否)
    eSendMail = 6,          --发送邮件(field1:接收者角色ID; field2:发送者昵称; field3:标题; field4:内容; field5:物品列表)
    eDelMail = 7,           --删除邮件
    eGetMail = 8,           --领取邮件物品
}
