package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

/**
 * 使用封印技能
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLaunchConditionLogic_34 extends AbstractPassiveSkillLaunchConditionLogic {

	@Override
	public AbstractPassiveSkillLaunchCondition newInstance() {
		return new PassiveSkillLaunchCondition_34();
	}

}
