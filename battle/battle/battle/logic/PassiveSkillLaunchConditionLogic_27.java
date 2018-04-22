package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

/**
 * 没有指定技能的其他怪全部死亡
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLaunchConditionLogic_27 extends AbstractPassiveSkillLaunchConditionLogic {

	@Override
	public AbstractPassiveSkillLaunchCondition newInstance() {
		return new PassiveSkillLaunchCondition_27();
	}

}
