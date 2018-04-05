package com.nucleus.logic.core.modules.battle.logic;

import java.util.Map;
import java.util.Set;

import org.springframework.stereotype.Service;

import com.nucleus.commons.utils.SplitUtils;

@Service
public class PassiveSkillLaunchConditionLogic_65 extends AbstractPassiveSkillLaunchConditionLogic {

	@Override
	public AbstractPassiveSkillLaunchCondition newInstance() {
		return new PassiveSkillLaunchCondition_65();
	}

	@Override
	public AbstractPassiveSkillLaunchCondition getInstance(Map<String, String> properties) {
		if (properties == null || properties.isEmpty())
			return null;
		PassiveSkillLaunchCondition_65 condition = (PassiveSkillLaunchCondition_65) newInstance();

		String skipConfigIdStr = properties.get("skipConfigIds");
		Set<Integer> skipConfigIds = SplitUtils.split2IntSet(skipConfigIdStr, "\\|");
		condition.setSkipConfigIds(skipConfigIds);
		return condition;
	}

}
