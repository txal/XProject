package com.nucleus.logic.core.modules.battle.logic;

import java.util.Map;
import java.util.Set;

import org.springframework.stereotype.Service;

import com.nucleus.commons.utils.SplitUtils;

/**
 * 己方存在指定技能则无法触发
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLaunchConditionLogic_15 extends AbstractPassiveSkillLaunchConditionLogic {

	@Override
	public AbstractPassiveSkillLaunchCondition getInstance(Map<String, String> properties) {
		if (properties == null || properties.isEmpty())
			return null;
		PassiveSkillLaunchCondition_15 condition = (PassiveSkillLaunchCondition_15) newInstance();
		condition.setId(Integer.parseInt(properties.get("id")));
		String skillIdStr = properties.get("skillIds");
		Set<Integer> skillIds = SplitUtils.split2IntSet(skillIdStr, "\\|");
		condition.setSkillIds(skillIds);
		;
		return condition;
	}

	@Override
	public AbstractPassiveSkillLaunchCondition newInstance() {
		return new PassiveSkillLaunchCondition_15();
	}

}
