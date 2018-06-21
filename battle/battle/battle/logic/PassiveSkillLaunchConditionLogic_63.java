package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

/**
 * 自己没有死
 * 
 * @author hwy
 *
 */
@Service
public class PassiveSkillLaunchConditionLogic_63 extends AbstractPassiveSkillLaunchConditionLogic {

	@Override
	public AbstractPassiveSkillLaunchCondition newInstance() {
		return new PassiveSkillLaunchCondition_63();
	}

}
