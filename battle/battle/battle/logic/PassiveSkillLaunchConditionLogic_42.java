package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

/**
 * 罡气 受到法术攻击时，有3%*技能等级的概率降低40%伤害
 *
 * @author zhanhua.xu
 */
@Service
public class PassiveSkillLaunchConditionLogic_42 extends AbstractPassiveSkillLaunchConditionLogic {

	@Override
	public AbstractPassiveSkillLaunchCondition newInstance() {
		return new PassiveSkillLaunchCondition_42();
	}

}
