package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

/**
 * 魔法系攻击次数取模
 * 
 * @author wangyu
 *
 */
@Service
public class PassiveSkillLaunchConditionLogic_79 extends AbstractPassiveSkillLaunchConditionLogic {

	@Override
	public AbstractPassiveSkillLaunchCondition newInstance() {
		return new PassiveSkillLaunchCondition_79();
	}

}
