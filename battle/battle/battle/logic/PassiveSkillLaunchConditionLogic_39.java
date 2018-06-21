package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

/**
 * 目标被击杀
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLaunchConditionLogic_39 extends AbstractPassiveSkillLaunchConditionLogic {

	@Override
	public AbstractPassiveSkillLaunchCondition newInstance() {
		return new PassiveSkillLaunchCondition_39();
	}

}
