package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;
/**
 * 第N回合及以后
 * @author wgy
 *
 */
@Service
public class PassiveSkillLaunchConditionLogic_55 extends AbstractPassiveSkillLaunchConditionLogic {

	@Override
	public AbstractPassiveSkillLaunchCondition newInstance() {
		return new PassiveSkillLaunchCondition_55();
	}

}