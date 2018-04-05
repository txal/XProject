package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

/**
 * 自己已召唤的单位不超过某个值
 * 
 * @author wangyu
 *
 */
@Service
public class PassiveSkillLaunchConditionLogic_80 extends AbstractPassiveSkillLaunchConditionLogic {

	@Override
	public AbstractPassiveSkillLaunchCondition newInstance() {
		return new PassiveSkillLaunchCondition_80();
	}

}
