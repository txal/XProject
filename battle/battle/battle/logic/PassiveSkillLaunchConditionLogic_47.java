package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

/**
 * 47使用群伤规则技能
 *
 * @author zhanhua.xu
 */
@Service
public class PassiveSkillLaunchConditionLogic_47 extends AbstractPassiveSkillLaunchConditionLogic {
	@Override
	public AbstractPassiveSkillLaunchCondition newInstance() {
		return new PassiveSkillLaunchCondition_47();
	}

}
