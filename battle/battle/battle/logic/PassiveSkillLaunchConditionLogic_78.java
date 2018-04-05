package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

/**
 * 是否有宠物
 * 
 * @author hwy
 *
 */
@Service
public class PassiveSkillLaunchConditionLogic_78 extends AbstractPassiveSkillLaunchConditionLogic {

	@Override
	public AbstractPassiveSkillLaunchCondition newInstance() {
		return new PassiveSkillLaunchCondition_78();
	}

}
