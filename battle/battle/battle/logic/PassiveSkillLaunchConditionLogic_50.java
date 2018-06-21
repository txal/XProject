package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

/**
 * 技能出现暴击
 *
 * @author zhanhua.xu
 */
@Service
public class PassiveSkillLaunchConditionLogic_50 extends AbstractPassiveSkillLaunchConditionLogic {
	@Override
	public AbstractPassiveSkillLaunchCondition newInstance() {
		return new PassiveSkillLaunchCondition_50();
	}
}
