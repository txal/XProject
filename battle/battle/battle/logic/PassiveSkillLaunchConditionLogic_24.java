package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

/**
 * 敌方指定目标死亡
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLaunchConditionLogic_24 extends AbstractPassiveSkillLaunchConditionLogic {

	@Override
	public AbstractPassiveSkillLaunchCondition newInstance() {
		return new PassiveSkillLaunchCondition_24();
	}

}
