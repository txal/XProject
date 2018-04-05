package com.nucleus.logic.core.modules.battle.logic;

import java.util.Map;
import java.util.Set;

import org.springframework.stereotype.Service;

import com.nucleus.commons.utils.SplitUtils;

/**
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLaunchConditionLogic_7 extends AbstractPassiveSkillLaunchConditionLogic {

	@Override
	public AbstractPassiveSkillLaunchCondition newInstance() {
		return new PassiveSkillLaunchCondition_7();
	}

	@Override
	public AbstractPassiveSkillLaunchCondition getInstance(Map<String, String> properties) {
		if (properties == null || properties.isEmpty())
			return null;
		PassiveSkillLaunchCondition_7 condition = (PassiveSkillLaunchCondition_7) newInstance();
		condition.setId(Integer.parseInt(properties.get("id")));
		String buffTypeStr = properties.get("buffTypes");
		Set<Integer> buffTypes = SplitUtils.split2IntSet(buffTypeStr, "\\|");
		condition.setBuffTypes(buffTypes);
		String buffIdStr = properties.get("buffIds");
		Set<Integer> buffIds = SplitUtils.split2IntSet(buffIdStr, "\\|");
		condition.setBuffIds(buffIds);
		return condition;
	}
}
