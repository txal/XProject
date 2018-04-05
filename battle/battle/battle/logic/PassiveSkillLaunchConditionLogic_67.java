package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

/**
 * 目标生命值低于指定百分比
 * 
 * @author ws
 *
 */
@Service
public class PassiveSkillLaunchConditionLogic_67 extends AbstractPassiveSkillLaunchConditionLogic {

	@Override
	public AbstractPassiveSkillLaunchCondition newInstance() {
		return new PassiveSkillLaunchCondition_67();
	}

}
