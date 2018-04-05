package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

/**
 * 使用复活类技能
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLaunchConditionLogic_32 extends AbstractPassiveSkillLaunchConditionLogic {

	@Override
	public AbstractPassiveSkillLaunchCondition newInstance() {
		return new PassiveSkillLaunchCondition_32();
	}

}
