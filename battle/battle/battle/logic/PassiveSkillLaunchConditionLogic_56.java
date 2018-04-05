package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

/**
 * 使用加血治疗技能(不包括特技)
 *
 * @author wgy
 */
@Service
public class PassiveSkillLaunchConditionLogic_56 extends AbstractPassiveSkillLaunchConditionLogic {
	@Override
	public AbstractPassiveSkillLaunchCondition newInstance() {
		return new PassiveSkillLaunchCondition_56();
	}
}
