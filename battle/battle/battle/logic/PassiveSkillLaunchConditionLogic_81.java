package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

/**
 * 目标为傀儡生物
 * 
 * @author wangyu
 *
 */
@Service
public class PassiveSkillLaunchConditionLogic_81 extends AbstractPassiveSkillLaunchConditionLogic {

	@Override
	public AbstractPassiveSkillLaunchCondition newInstance() {
		return new PassiveSkillLaunchCondition_81();
	}

}
