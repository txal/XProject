package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;
/**
 * 任一目标死亡
 * @author wgy
 *
 */
@Service
public class PassiveSkillLaunchConditionLogic_53 extends AbstractPassiveSkillLaunchConditionLogic {

	@Override
	public AbstractPassiveSkillLaunchCondition newInstance() {
		return new PassiveSkillLaunchCondition_53();
	}

}
