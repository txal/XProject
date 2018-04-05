package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

/**
 * 使用某技能小于指定次数
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLaunchConditionLogic_31 extends AbstractPassiveSkillLaunchConditionLogic {

	@Override
	public AbstractPassiveSkillLaunchCondition newInstance() {
		return new PassiveSkillLaunchCondition_31();
	}

}
