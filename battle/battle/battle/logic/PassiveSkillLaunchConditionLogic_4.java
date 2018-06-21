package com.nucleus.logic.core.modules.battle.logic;

import java.util.Map;
import java.util.Set;

import org.springframework.stereotype.Service;

import com.nucleus.commons.utils.SplitUtils;

/**
 * 技能互斥(1存在指定技能则该技能无效;2己方有特定技能则忽略规则1)
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLaunchConditionLogic_4 extends AbstractPassiveSkillLaunchConditionLogic {

	@Override
	public AbstractPassiveSkillLaunchCondition getInstance(Map<String, String> properties) {
		if (properties == null || properties.isEmpty())
			return null;
		PassiveSkillLaunchCondition_4 condition = (PassiveSkillLaunchCondition_4) newInstance();
		condition.setId(Integer.parseInt(properties.get("id")));
		String skillIdStr = properties.get("skillIds");
		Set<Integer> skillIds = SplitUtils.split2IntSet(skillIdStr, "\\|");
		condition.setSkillIds(skillIds);
		String ignoreSkillIdStr = properties.get("ignoreSkillIds");
		Set<Integer> ignoreSkillIds = SplitUtils.split2IntSet(ignoreSkillIdStr, "\\|");
		condition.setIgnoreSkillIds(ignoreSkillIds);
		return condition;
	}

	@Override
	public AbstractPassiveSkillLaunchCondition newInstance() {
		return new PassiveSkillLaunchCondition_4();
	}

}
