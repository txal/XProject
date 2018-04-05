package com.nucleus.logic.core.modules.battle.logic;

import java.util.Map;

import org.springframework.stereotype.Service;

/**
 * 是否宠物
 * 
 * @author hwy
 *
 */
@Service
public class PassiveSkillLaunchConditionLogic_77 extends AbstractPassiveSkillLaunchConditionLogic {

	@Override
	public AbstractPassiveSkillLaunchCondition newInstance() {
		return new PassiveSkillLaunchCondition_77();
	}

	@Override
	public AbstractPassiveSkillLaunchCondition getInstance(Map<String, String> properties) {
		if (properties == null || properties.isEmpty())
			return null;
		PassiveSkillLaunchCondition_77 condition = (PassiveSkillLaunchCondition_77) newInstance();
		if (properties.get("charatorType") != null) {
			condition.setCharatorType((Integer.parseInt(properties.get("charatorType"))));
		}
		return condition;
	}

}
