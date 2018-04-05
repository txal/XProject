package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;
/**
 * 敌方有单位死亡(技能召唤、援助单位、鬼魂宠物除外)
 * @author wgy
 *
 */
@Service
public class PassiveSkillLaunchConditionLogic_54 extends AbstractPassiveSkillLaunchConditionLogic {

	@Override
	public AbstractPassiveSkillLaunchCondition newInstance() {
		return new PassiveSkillLaunchCondition_54();
	}

}
