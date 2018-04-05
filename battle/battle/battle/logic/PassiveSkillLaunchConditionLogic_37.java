package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

/**
 * 所有消耗mp的法术
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLaunchConditionLogic_37 extends AbstractPassiveSkillLaunchConditionLogic {

	@Override
	public AbstractPassiveSkillLaunchCondition newInstance() {
		return new PassiveSkillLaunchCondition_37();
	}

}
