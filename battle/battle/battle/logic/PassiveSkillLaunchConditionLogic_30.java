package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

/**
 * 已召唤小怪数量小于指定值
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLaunchConditionLogic_30 extends AbstractPassiveSkillLaunchConditionLogic {

	@Override
	public AbstractPassiveSkillLaunchCondition newInstance() {
		return new PassiveSkillLaunchCondition_30();
	}

}
