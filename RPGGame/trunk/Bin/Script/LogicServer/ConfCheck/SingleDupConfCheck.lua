local function _SingleDupConfCheck()
	local nCount = 0
	for _, tConf in pairs(ctSingleDup) do
		assert(ctChapterConf[tConf.nChapter], "关卡:"..tConf.nID.."章节:"..tConf.nChapter.."不存在")
		nCount = nCount + 1
	end
	--assert(nCount == #ctSingleDup, "SingleDup.xml表的副本ID必须是有序递增")
end
_SingleDupConfCheck()


--生成有序配置表
_tChapterDupConf = {}
local function _BuildChapterDupConf()
	for nDupID, tConf in pairs(ctSingleDup) do
		if not _tChapterDupConf[tConf.nChapter] then
			_tChapterDupConf[tConf.nChapter] = {}
		end
		table.insert(_tChapterDupConf[tConf.nChapter], tConf)
	end
	for _, tDupConfList in ipairs(_tChapterDupConf) do
		table.sort(tDupConfList, function(tDup1, tDup2) return tDup1.nID < tDup2.nID end)
	end
end
_BuildChapterDupConf()

--章节副本配置
function GetChapterDupConf()
	return _tChapterDupConf
end
