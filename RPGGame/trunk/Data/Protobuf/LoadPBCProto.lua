local tProtoList =
{
"achieve.proto",
"actfb.proto",
"actlc.proto",
"actld.proto",
"actxy.proto",
"actyy.proto",
"actzeroyuan.proto",
"appellation.proto",
"arena.proto",
"artifact.proto",
"bahuanghuozhen.proto",
"baotu.proto",
"battle.proto",
"battledup.proto",
"chongbang.proto",
"common.proto",
"dailyactivity.proto",
"drawspirit.proto",
"everydaygift.proto",
"exchangeactivity.proto",
"fabao.proto",
"findaward.proto",
"formation.proto",
"friend.proto",
"fund.proto",
"gift.proto",
"global.proto",
"growthtargetact.proto",
"guaji.proto",
"guidetask.proto",
"hallfame.proto",
"holidayactivity.proto",
"house.proto",
"invite.proto",
"itemquery.proto",
"keju.proto",
"keyexchange.proto",
"knapsack.proto",
"leideng.proto",
"lifeskill.proto",
"login.proto",
"mail.proto",
"market.proto",
"marriage.proto",
"monthcard.proto",
"multiconfirmbox.proto",
"notice.proto",
"partner.proto",
"paypush.proto",
"pet.proto",
"playerguide.proto",
"practice.proto",
"pveactivity.proto",
"pvpactivity.proto",
"qiandao.proto",
"ranking.proto",
"relationship.proto",
"role.proto",
"rolestate.proto",
"rolewash.proto",
"scene.proto",
"shangjintask.proto",
"shenjizhufu.proto",
"shenmibaoxiang.proto",
"shenmozhi.proto",
"shiliantask.proto",
"shimentask.proto",
"shizhuang.proto",
"shop.proto",
"skill.proto",
"sysopen.proto",
"SystemMall.proto",
"talk.proto",
"targettask.proto",
"tasksystem.proto",
"team.proto",
"tiandibaowu.proto",
"timeaward.proto",
"union.proto",
"upgradebag.proto",
"vip.proto",
"wddownload.proto",
"willopen.proto",
"wuguicaiyun.proto",
"yaoshoutuxi.proto"
};

function LoadProto(sPath)
	assert(parser.register(tProtoList, sPath), "load proto faild!")
end

function pbc_encode(proto, value)
	return protobuf.encode(proto, value)
end

function pbc_decode(proto, value, length)
	if not proto or not value then
		return
	end
	return protobuf.decode(proto, value, length)
end

