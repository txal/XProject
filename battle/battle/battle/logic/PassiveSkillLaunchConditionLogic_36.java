package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

/**
 * 给目标加特定buff
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLaunchConditionLogic_36 extends AbstractPassiveSkillLaunchConditionLogic {

	@Override
	public AbstractPassiveSkillLaunchCondition newInstance() {
		return new PassiveSkillLaunchCondition_36();
	}

}
