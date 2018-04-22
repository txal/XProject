package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

/**
 * @author hwy
 *
 */
@Service
public class PassiveSkillLaunchConditionLogic_58 extends AbstractPassiveSkillLaunchConditionLogic {

	@Override
	public AbstractPassiveSkillLaunchCondition newInstance() {
		return new PassiveSkillLaunchCondition_58();
	}

}
