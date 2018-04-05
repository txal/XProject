package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

/**
 * 造成伤害值尾数为指定值
 * 
 * @author wangyu
 *
 */
@Service
public class PassiveSkillLaunchConditionLogic_84 extends AbstractPassiveSkillLaunchConditionLogic {

	@Override
	public AbstractPassiveSkillLaunchCondition newInstance() {
		return new PassiveSkillLaunchCondition_84();
	}

}
