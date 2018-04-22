package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

/**
 * 前N回合
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLaunchConditionLogic_13 extends AbstractPassiveSkillLaunchConditionLogic {

	@Override
	public AbstractPassiveSkillLaunchCondition newInstance() {
		return new PassiveSkillLaunchCondition_13();
	}

}
