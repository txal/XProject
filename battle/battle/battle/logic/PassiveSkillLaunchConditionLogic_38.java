package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

/**
 * 当前技能是否可被反击
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLaunchConditionLogic_38 extends AbstractPassiveSkillLaunchConditionLogic {

	@Override
	public AbstractPassiveSkillLaunchCondition newInstance() {
		return new PassiveSkillLaunchCondition_38();
	}

}
