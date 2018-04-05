package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

/**
 * 是否被封印状态
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLaunchConditionLogic_19 extends AbstractPassiveSkillLaunchConditionLogic {

	@Override
	public AbstractPassiveSkillLaunchCondition newInstance() {
		return new PassiveSkillLaunchCondition_19();
	}

}
