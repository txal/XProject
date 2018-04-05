package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

/**
 * 仅对头号目标有效
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLaunchConditionLogic_35 extends AbstractPassiveSkillLaunchConditionLogic {

	@Override
	public AbstractPassiveSkillLaunchCondition newInstance() {
		return new PassiveSkillLaunchCondition_35();
	}

}
