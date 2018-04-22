package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;
/**
 * 使用门派默认攻击技能
 * @author wgy
 *
 */
@Service
public class PassiveSkillLaunchConditionLogic_52 extends AbstractPassiveSkillLaunchConditionLogic {

	@Override
	public AbstractPassiveSkillLaunchCondition newInstance() {
		return new PassiveSkillLaunchCondition_52();
	}

}
