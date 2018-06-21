package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

/**
 * 本队死亡单位数量大于等于指定值
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLaunchConditionLogic_29 extends AbstractPassiveSkillLaunchConditionLogic {

	@Override
	public AbstractPassiveSkillLaunchCondition newInstance() {
		return new PassiveSkillLaunchCondition_29();
	}

}
