package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

/**
 * 使用加血治疗技能
 *
 * @author zhanhua.xu
 */
@Service
public class PassiveSkillLaunchConditionLogic_48 extends AbstractPassiveSkillLaunchConditionLogic {
	@Override
	public AbstractPassiveSkillLaunchCondition newInstance() {
		return new PassiveSkillLaunchCondition_48();
	}
}
