package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

/**
 * 妙手空空
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLaunchConditionLogic_40 extends AbstractPassiveSkillLaunchConditionLogic {

	@Override
	public AbstractPassiveSkillLaunchCondition newInstance() {
		return new PassiveSkillLaunchCondition_40();
	}

}
