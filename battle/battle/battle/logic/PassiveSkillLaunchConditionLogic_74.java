package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

/**
 * 使用指定技能时（优先检查强制技能，再查当前技能）
 * 
 * @author hwy
 *
 */
@Service
public class PassiveSkillLaunchConditionLogic_74 extends AbstractPassiveSkillLaunchConditionLogic {

	@Override
	public AbstractPassiveSkillLaunchCondition newInstance() {
		return new PassiveSkillLaunchCondition_74();
	}

}
