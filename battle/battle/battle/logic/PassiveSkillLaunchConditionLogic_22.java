package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

/**
 * 己方场上还存活除自己之外的其他单位
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLaunchConditionLogic_22 extends AbstractPassiveSkillLaunchConditionLogic {

	@Override
	public AbstractPassiveSkillLaunchCondition newInstance() {
		return new PassiveSkillLaunchCondition_22();
	}

}
