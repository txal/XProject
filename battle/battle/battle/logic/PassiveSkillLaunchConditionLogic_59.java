package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

/**
 * 已召唤小怪数量大于指定值
 * 
 * @author hwy
 *
 */
@Service
public class PassiveSkillLaunchConditionLogic_59 extends AbstractPassiveSkillLaunchConditionLogic {

	@Override
	public AbstractPassiveSkillLaunchCondition newInstance() {
		return new PassiveSkillLaunchCondition_59();
	}

}
