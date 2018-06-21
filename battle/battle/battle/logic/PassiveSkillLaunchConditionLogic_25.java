package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

/**
 * 己方指定目标未死
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLaunchConditionLogic_25 extends AbstractPassiveSkillLaunchConditionLogic {

	@Override
	public AbstractPassiveSkillLaunchCondition newInstance() {
		return new PassiveSkillLaunchCondition_25();
	}

}
