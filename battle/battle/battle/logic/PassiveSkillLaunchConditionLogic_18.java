package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

/**
 * 每隔n回合
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLaunchConditionLogic_18 extends AbstractPassiveSkillLaunchConditionLogic {

	@Override
	public AbstractPassiveSkillLaunchCondition newInstance() {
		return new PassiveSkillLaunchCondition_18();
	}

}
