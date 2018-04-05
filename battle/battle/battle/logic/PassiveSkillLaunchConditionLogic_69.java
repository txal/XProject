package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

/**
 * SP少于指定值
 * 
 * @author hwy
 *
 */
@Service
public class PassiveSkillLaunchConditionLogic_69 extends AbstractPassiveSkillLaunchConditionLogic {

	@Override
	public AbstractPassiveSkillLaunchCondition newInstance() {
		return new PassiveSkillLaunchCondition_69();
	}

}
