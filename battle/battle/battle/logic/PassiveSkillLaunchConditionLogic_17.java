package com.nucleus.logic.core.modules.battle.logic;

import java.util.Map;
import java.util.Set;

import org.springframework.stereotype.Service;

import com.nucleus.commons.utils.SplitUtils;

/**
 * buff效果增强
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLaunchConditionLogic_17 extends AbstractPassiveSkillLaunchConditionLogic {

	@Override
	public AbstractPassiveSkillLaunchCondition newInstance() {
		return new PassiveSkillLaunchCondition_17();
	}

	@Override
	public AbstractPassiveSkillLaunchCondition getInstance(Map<String, String> properties) {
		if (properties == null || properties.isEmpty())
			return null;
		PassiveSkillLaunchCondition_17 condition = (PassiveSkillLaunchCondition_17) newInstance();
		condition.setId(Integer.parseInt(properties.get("id")));
		String buffTypesStr = properties.get("buffTypes");
		Set<Integer> buffTypes = SplitUtils.split2IntSet(buffTypesStr, "\\|");
		condition.setBuffTypes(buffTypes);
		return condition;
	}
}
