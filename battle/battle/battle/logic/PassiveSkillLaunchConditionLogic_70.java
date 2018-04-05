package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

/**
 * HP损失导致SP增加大于某值
 * 
 * @author hwy
 *
 */
@Service
public class PassiveSkillLaunchConditionLogic_70 extends AbstractPassiveSkillLaunchConditionLogic {

	@Override
	public AbstractPassiveSkillLaunchCondition newInstance() {
		return new PassiveSkillLaunchCondition_70();
	}

}
