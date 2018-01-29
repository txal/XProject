local tProtoList =
{
"achievements.proto",
"awardrecord.proto",
"battle.proto",
"broadcast.proto",
"chengzhidiqiu.proto",
"chuxiugong.proto",
"chuxun.proto",
"daqinghuangbang.proto",
"dayrecharge.proto",
"diandeng.proto",
"fashion.proto",
"global.proto",
"guoku.proto",
"guoshiguan.proto",
"huakui.proto",
"huangzi.proto",
"junjichu.proto",
"keyexchange.proto",
"leichong.proto",
"leideng.proto",
"lifanyuan.proto",
"login.proto",
"mail.proto",
"mingchen.proto",
"mobai.proto",
"neige.proto",
"party.proto",
"qiandao.proto",
"qifu.proto",
"qinganzhe.proto",
"redpoint.proto",
"shenjizhufu.proto",
"shenmibaoxiang.proto",
"shoulie.proto",
"talk.proto",
"task.proto",
"tiandeng.proto",
"timeaward.proto",
"timedraw.proto",
"timegift.proto",
"timemall.proto",
"tv.proto",
"union.proto",
"vip.proto",
"wabao.proto",
"weekrecharge.proto",
"weifusifang.proto",
"yihongyuan.proto",
"youwan.proto",
"zaorenqiangguo.proto",
"zouzhang.proto"
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

