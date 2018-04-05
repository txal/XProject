package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

/**
 * 己方有死亡单位
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLaunchConditionLogic_23 extends AbstractPassiveSkillLaunchConditionLogic {

	@Override
	public AbstractPassiveSkillLaunchCondition newInstance() {
		return new PassiveSkillLaunchCondition_23();
	}

}
