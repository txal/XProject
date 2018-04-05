/**
 * 
 */
package com.nucleus.logic.core.modules.battlebuff;

import org.springframework.stereotype.Service;

import com.nucleus.commons.utils.RandomUtils;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;
import com.nucleus.logic.core.modules.battlebuff.model.BuffLogicParam;
import com.nucleus.logic.core.modules.battlebuff.model.BuffLogicParam_16;

/**
 * 免疫物理/法术攻击
 * 
 * @author wgy
 *
 */
@Service
public class BattleBuffLogic_16 extends BattleBuffLogicAdapter {

	@Override
	protected BuffLogicParam newParam() {
		return new BuffLogicParam_16();
	}

	@Override
	public void beforeSkillFire(CommandContext commandContext, BattleBuffEntity buffEntity) {
		BuffLogicParam_16 param = (BuffLogicParam_16) buffEntity.battleBuff().getBuffParam();
		if (param == null)
			return;
		if (commandContext.skill().getSkillAttackType() != param.getAttackType())
			return;
		boolean success = RandomUtils.baseRandomHit(param.getRate());
		commandContext.setBuffAntiSkill(success);
	}
}
