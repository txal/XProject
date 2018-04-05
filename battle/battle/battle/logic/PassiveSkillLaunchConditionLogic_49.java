package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

/**
 * 回合内指定被动技能触发次数(超/未超)上限
 *
 * @author wgy
 */
@Service
public class PassiveSkillLaunchConditionLogic_49 extends AbstractPassiveSkillLaunchConditionLogic {
	@Override
	public AbstractPassiveSkillLaunchCondition newInstance() {
		return new PassiveSkillLaunchCondition_49();
	}
}
