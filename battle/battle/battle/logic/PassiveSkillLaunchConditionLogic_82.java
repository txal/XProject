package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

/**
 * 目标受击大于等于气血上限百分比
 * 
 * @author wangyu
 *
 */
@Service
public class PassiveSkillLaunchConditionLogic_82 extends AbstractPassiveSkillLaunchConditionLogic {

	@Override
	public AbstractPassiveSkillLaunchCondition newInstance() {
		return new PassiveSkillLaunchCondition_82();
	}

}
