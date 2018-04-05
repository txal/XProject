package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

/**
 * 单回合掉血大于等于血气上限百分比
 * 
 * @author hwy
 *
 */
@Service
public class PassiveSkillLaunchConditionLogic_73 extends AbstractPassiveSkillLaunchConditionLogic {

	@Override
	public AbstractPassiveSkillLaunchCondition newInstance() {
		return new PassiveSkillLaunchCondition_73();
	}

}
