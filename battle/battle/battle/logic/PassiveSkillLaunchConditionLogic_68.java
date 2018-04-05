package com.nucleus.logic.core.modules.battle.logic;

import java.util.Map;
import java.util.Set;

import org.springframework.stereotype.Service;

import com.nucleus.commons.utils.SplitUtils;

/**
 * 目标生命值低于指定百分比
 * 
 * @author ws
 *
 */
@Service
public class PassiveSkillLaunchConditionLogic_68 extends AbstractPassiveSkillLaunchConditionLogic {

	@Override
	public AbstractPassiveSkillLaunchCondition getInstance(Map<String, String> properties) {
		if (properties == null || properties.isEmpty())
			return null;
		PassiveSkillLaunchCondition_68 condition = (PassiveSkillLaunchCondition_68) newInstance();
		condition.setId(Integer.parseInt(properties.get("id")));
		String skillIdStr = properties.get("skillIds");
		Set<Integer> skillIds = SplitUtils.split2IntSet(skillIdStr, "\\|");
		condition.setSkillIds(skillIds);
		return condition;
	}

	@Override
	public AbstractPassiveSkillLaunchCondition newInstance() {
		return new PassiveSkillLaunchCondition_68();
	}

}
