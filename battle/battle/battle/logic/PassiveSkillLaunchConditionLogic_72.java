package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

/**
 * 回合首次受击
 * 
 * @author hwy
 *
 */
@Service
public class PassiveSkillLaunchConditionLogic_72 extends AbstractPassiveSkillLaunchConditionLogic {

	@Override
	public AbstractPassiveSkillLaunchCondition newInstance() {
		return new PassiveSkillLaunchCondition_72();
	}

}
