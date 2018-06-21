package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

/**
 * 法术攻击
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLaunchConditionLogic_5 extends AbstractPassiveSkillLaunchConditionLogic {

	@Override
	public AbstractPassiveSkillLaunchCondition newInstance() {
		return new PassiveSkillLaunchCondition_5();
	}

}
