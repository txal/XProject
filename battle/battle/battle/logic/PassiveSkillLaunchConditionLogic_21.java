package com.nucleus.logic.core.modules.battle.logic;

import java.util.Map;
import java.util.Set;

import org.springframework.stereotype.Service;

import com.nucleus.commons.utils.SplitUtils;

/**
 * 目标存在指定buff则技能无法触发
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLaunchConditionLogic_21 extends AbstractPassiveSkillLaunchConditionLogic {

	@Override
	public AbstractPassiveSkillLaunchCondition newInstance() {
		return new PassiveSkillLaunchCondition_21();
	}

	@Override
	public AbstractPassiveSkillLaunchCondition getInstance(Map<String, String> properties) {
		if (properties == null || properties.isEmpty())
			return null;
		PassiveSkillLaunchCondition_21 condition = (PassiveSkillLaunchCondition_21) newInstance();
		condition.setId(Integer.parseInt(properties.get("id")));
		String buffIdsStr = properties.get("buffIds");
		Set<Integer> buffIds = SplitUtils.split2IntSet(buffIdsStr, "\\|");
		condition.setBuffIds(buffIds);
		return condition;
	}

}
