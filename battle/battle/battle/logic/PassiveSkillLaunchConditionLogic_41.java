package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

/**
 * 护体 受到物理攻击时，有3%*技能等级的概率降低40%伤害
 *
 * @author zhanhua.xu
 */
@Service
public class PassiveSkillLaunchConditionLogic_41 extends AbstractPassiveSkillLaunchConditionLogic {

	@Override
	public AbstractPassiveSkillLaunchCondition newInstance() {
		return new PassiveSkillLaunchCondition_41();
	}

}
