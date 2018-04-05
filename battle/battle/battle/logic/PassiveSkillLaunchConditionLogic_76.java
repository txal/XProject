package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

/**
 * 受击致死
 * 
 * @author wangyu
 *
 */
@Service
public class PassiveSkillLaunchConditionLogic_76 extends AbstractPassiveSkillLaunchConditionLogic {

	@Override
	public AbstractPassiveSkillLaunchCondition newInstance() {
		return new PassiveSkillLaunchCondition_76();
	}

}
