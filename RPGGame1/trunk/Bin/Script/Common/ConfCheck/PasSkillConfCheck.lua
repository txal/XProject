local function _PasSkillConfCheck()
	for _, tConf in pairs(ctPetSkillConf) do
		if tConf.nBuffNumber > 0 then
			assert(ctBuffConf[tConf.nBuffNumber], "BUFF配置不存在:"..tConf.nBuffNumber)
		end
	end
end
_PasSkillConfCheck()