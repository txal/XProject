/**
 * 
 */
package com.nucleus.logic.core.modules.battlebuff;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;
import com.nucleus.logic.core.modules.battlebuff.model.BuffLogicParam;
import com.nucleus.logic.core.modules.battlebuff.model.BuffLogicParam_20;

/**
 * 特殊处理逻辑
 * 
 * 360蛊毒buff功能 每回合掉血为伤害值的10%、20%、30%、40%; 2015毒爆术效果 结算目标身上全部的毒伤害
 * 
 * @author zhanhua.xu
 *
 */
@Service
public class BattleBuffLogic_20 extends BattleBuffLogicAdapter {

	@Override
	protected BuffLogicParam newParam() {
		return new BuffLogicParam_20();
	}

	@Override
	public void beforeSkillFire(CommandContext commandContext, BattleBuffEntity buffEntity) {
		if (commandContext == null)
			return;
		BattleBuff battleBuff = buffEntity.battleBuff();
		if (battleBuff == null)
			return;
		BuffLogicParam_20 param = (BuffLogicParam_20) buffEntity.battleBuff().getBuffParam();
		if (param.getSkillId() != commandContext.skill().getId())
			return;

		float rate = 0.6F + buffEntity.getBuffPersistRound() / 10F;
		int damageInput = (int) (buffEntity.hitDamageInput() * rate);
		int damageOutput = commandContext.getDamageOutput();
		damageOutput -= damageInput;
		commandContext.setDamageOutput(damageOutput);
	}
}
