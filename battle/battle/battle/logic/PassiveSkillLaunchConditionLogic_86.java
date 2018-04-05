package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

/**
 * 单体攻击（普攻、物理单体、法术单体）
 * 
 * @author wangyu
 *
 */
@Service
public class PassiveSkillLaunchConditionLogic_86 extends AbstractPassiveSkillLaunchConditionLogic {

	@Override
	public AbstractPassiveSkillLaunchCondition newInstance() {
		return new PassiveSkillLaunchCondition_86();
	}

}
