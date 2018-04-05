package com.nucleus.logic.core.modules.battle.logic;

import java.util.Map;

import org.springframework.stereotype.Service;

import com.nucleus.commons.utils.SplitUtils;

/**
 * 鬼魂生物无效
 * 
 * @author wgy
 *
 */
@Service
public class SkillTargetFilterLogic_1 extends AbstractSkillTargetFilterLogic {

	@Override
	public AbstractSkillTargetFilter newInstance() {
		return new SkillTargetFilter_1();
	}

	@Override
	public AbstractSkillTargetFilter getInstance(Map<String, String> properties) {
		SkillTargetFilter_1 filter = (SkillTargetFilter_1) newInstance();
		filter.setId(Integer.parseInt(properties.get("id")));
		String skillIds = properties.get("skillIds");
		filter.setSkillIds(SplitUtils.split2IntSet(skillIds, "\\|"));
		return filter;
	}
}
