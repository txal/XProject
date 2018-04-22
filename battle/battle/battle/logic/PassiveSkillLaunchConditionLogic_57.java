package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

/**
 * 
 *参战后每隔N回合
 * @author wgy
 */
@Service
public class PassiveSkillLaunchConditionLogic_57 extends AbstractPassiveSkillLaunchConditionLogic {
	@Override
	public AbstractPassiveSkillLaunchCondition newInstance() {
		return new PassiveSkillLaunchCondition_57();
	}
}
