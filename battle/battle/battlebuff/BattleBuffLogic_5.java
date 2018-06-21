package com.nucleus.logic.core.modules.battlebuff;

import org.springframework.stereotype.Service;

import com.nucleus.commons.utils.RandomUtils;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;
import com.nucleus.logic.core.modules.battlebuff.model.BuffLogicParam;
import com.nucleus.logic.core.modules.battlebuff.model.BuffLogicParam_5;

/**
 * n回合内有机率免疫攻击法术
 * 
 * @author wgy
 *
 */
@Service
public class BattleBuffLogic_5 extends BattleBuffLogicAdapter {

	@Override
	protected BuffLogicParam newParam() {
		return new BuffLogicParam_5();
	}

	@Override
	public void beforeSkillFire(CommandContext commandContext, BattleBuffEntity buffEntity) {
		if (!commandContext.skill().ifMagicAttack())
			return;
		BuffLogicParam_5 param = (BuffLogicParam_5) buffEntity.battleBuff().getBuffParam();
		boolean success = RandomUtils.baseRandomHit(param.getRate());
		commandContext.setBuffAntiSkill(success);
	}
}
