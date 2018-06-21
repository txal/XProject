package com.nucleus.logic.core.modules.battlebuff;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;
import com.nucleus.logic.core.modules.battlebuff.model.BuffLogicParam;
import com.nucleus.logic.core.modules.battlebuff.model.BuffLogicParam_5;

/**
 * 免疫所有法术并且反弹伤害
 * 
 * @author wgy
 *
 */
@Service
public class BattleBuffLogic_6 extends BattleBuffLogicAdapter {
	@Autowired(required = false)
	private BattleBuffLogic_4 reboundLogic;
	@Autowired(required = false)
	private BattleBuffLogic_5 antiSkillLogic;

	@Override
	protected BuffLogicParam newParam() {
		return new BuffLogicParam_5();
	}

	@Override
	public void beforeSkillFire(CommandContext commandContext, BattleBuffEntity buffEntity) {
		if (antiSkillLogic != null)
			antiSkillLogic.beforeSkillFire(commandContext, buffEntity);
	}

	@Override
	public void underAttack(CommandContext commandContext, BattleBuffEntity buffEntity) {
		if (reboundLogic != null && commandContext.skill().ifMagicAttack())
			reboundLogic.underAttack(commandContext, buffEntity);
	}
}
