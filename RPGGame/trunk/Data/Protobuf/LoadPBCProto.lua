local tProtoList =
{
"achievements.proto",
"awardrecord.proto",
"battle.proto",
"chuxiugong.proto",
"daqinghuangbang.proto",
"dayrecharge.proto",
"diandeng.proto",
"exchange.proto",
"fashion.proto",
"global.proto",
"guoshiguan.proto",
"huakui.proto",
"huangzi.proto",
"Knapsack.proto",
"leichong.proto",
"leideng.proto",
"login.proto",
"mail.proto",
"mobai.proto",
"party.proto",
"qiandao.proto",
"redpoint.proto",
"scene.proto",
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
"union.proto",
"vip.proto",
"wabao.proto",
"weekrecharge.proto"
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

