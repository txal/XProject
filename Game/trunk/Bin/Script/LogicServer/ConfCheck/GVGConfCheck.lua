local function _GVGConfCheck()
	assert(ctBugHoleEtc[1].nNewbieFights <= #ctNewbieConf, "新手战斗场次太多,在newbieconf.xml")
end
_GVGConfCheck()