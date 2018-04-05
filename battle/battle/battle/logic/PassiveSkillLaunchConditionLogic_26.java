package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

/**
 * 除自己之外全部小怪死亡
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLaunchConditionLogic_26 extends AbstractPassiveSkillLaunchConditionLogic {

	@Override
	public AbstractPassiveSkillLaunchCondition newInstance() {
		return new PassiveSkillLaunchCondition_26();
	}

}
