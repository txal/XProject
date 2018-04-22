package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

/**
 * PVP条件下发动
 * 
 * @author hwy
 *
 */
@Service
public class PassiveSkillLaunchConditionLogic_60 extends AbstractPassiveSkillLaunchConditionLogic {

	@Override
	public AbstractPassiveSkillLaunchCondition newInstance() {
		return new PassiveSkillLaunchCondition_60();
	}

}
