package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

/**
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLaunchConditionLogic_20 extends AbstractPassiveSkillLaunchConditionLogic {

	@Override
	public AbstractPassiveSkillLaunchCondition newInstance() {
		return new PassiveSkillLaunchCondition_20();
	}

}
