package com.nucleus.logic.core.modules.battlebuff.model;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.dto.VideoActionTargetState;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battlebuff.BattleBuffLogicAdapter;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff.BattleBasePropertyType;

/**
 * 死后n回合复活
 * 
 * @author wgy
 *
 */
@Service
public class BattleBuffLogic_10 extends BattleBuffLogicAdapter {

	@Override
	protected BuffLogicParam newParam() {
		return new BuffLogicParam_10();
	}

	@Override
	public void onRoundStart(BattleBuffEntity buffEntity) {
		BattleSoldier soldier = buffEntity.getEffectSoldier();
		if (!soldier.isDead())
			return;
		int round = soldier.battle().getCount() - soldier.getDeadRound();
		BuffLogicParam_10 param = (BuffLogicParam_10) buffEntity.battleBuff().getBuffParam();
		if (round < param.getRound())
			return;
		float rate = buffEntity.basePropertyEffect(BattleBasePropertyType.HpRate);
		int hp = (int) (soldier.maxHp() * rate);
		soldier.increaseHp(hp);
		soldier.currentVideoRound().readyAction().addTargetState(new VideoActionTargetState(soldier, hp, 0, false));
	}
}
