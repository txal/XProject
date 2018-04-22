package com.nucleus.logic.core.modules.battlebuff;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff.BattleBasePropertyType;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;
import com.nucleus.logic.core.modules.battlebuff.model.BuffLogicParam;
import com.nucleus.logic.core.modules.battlebuff.model.BuffLogicParam_9;

/**
 * 蝎毒buff特殊逻辑：被"毒气攻心"技能攻击会提前结算buff效果
 * 
 * @author wgy
 *
 */
@Service
public class BattleBuffLogic_9 extends BattleBuffLogicAdapter {
	@Override
	protected BuffLogicParam newParam() {
		return new BuffLogicParam_9();
	}

	@Override
	public void beforeSkillFire(CommandContext commandContext, BattleBuffEntity buffEntity) {
		BuffLogicParam_9 param = (BuffLogicParam_9) buffEntity.battleBuff().getBuffParam();
		if (param.getSkillId() == commandContext.skill().getId()) {
			int value = (int) buffEntity.basePropertyEffect(BattleBasePropertyType.Hp);
			buffEntity.setBuffEffectValue(value);
			int damageOutput = buffEntity.getBuffPersistRound() * buffEntity.getBuffEffectValue();
			damageOutput += commandContext.getDamageOutput();
			commandContext.setDamageOutput(damageOutput);
		}
	}
}
