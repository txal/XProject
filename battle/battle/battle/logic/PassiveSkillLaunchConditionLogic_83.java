package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

/**
 * 使用物理物理系/魔法系技能，按几率触发
 * 
 * @author wangyu
 *
 */
@Service
public class PassiveSkillLaunchConditionLogic_83 extends AbstractPassiveSkillLaunchConditionLogic {

	@Override
	public AbstractPassiveSkillLaunchCondition newInstance() {
		return new PassiveSkillLaunchCondition_83();
	}

}
