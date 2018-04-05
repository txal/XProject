/**
 * 
 */
package com.nucleus.logic.core.modules.battlebuff;

import org.apache.commons.lang3.math.NumberUtils;
import org.springframework.stereotype.Service;

import com.nucleus.commons.utils.RandomUtils;
import com.nucleus.logic.core.modules.battle.dto.VideoBuffAddTargetState;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;
import com.nucleus.logic.core.modules.battlebuff.model.BuffLogicParam;
import com.nucleus.logic.core.modules.battlebuff.model.BuffLogicParam_30;

/**
 * 血疫蔓延,中此buff会给该单位位置附近(position+(-)1)目标附加另一buff
 * 
 * @author wgy
 *
 */
@Service
public class BattleBuffLogic_30 extends BattleBuffLogicAdapter {

	// 阵型位置布局，各元素代表阵型位置索引,根据每个位置索引查找左右相邻位置索引
	public static final int[][] positions = new int[][] { { 9, 7, 6, 8, 10 }, { 4, 2, 1, 3, 5 }, { 12, 11, 13 } };

	@Override
	protected BuffLogicParam newParam() {
		return new BuffLogicParam_30();
	}

	@Override
	public void onActionEnd(CommandContext commandContext, BattleBuffEntity buffEntity) {
		if (buffEntity.getBuffEffectTimes() < 1)
			return;
		BattleSoldier currentSoldier = buffEntity.getEffectSoldier();
		int pos = currentSoldier.getPosition();
		currentSoldier.team().aliveSoldiers().stream().filter(s -> {
			int[] arr = leftRightPos(pos);
			return s.getPosition() == arr[0] || s.getPosition() == arr[1];
		}).forEach(s -> {
			BuffLogicParam_30 param = (BuffLogicParam_30) buffEntity.battleBuff().getBuffParam();
			BattleBuff battleBuff = BattleBuff.get(param.getBuffId());
			if (battleBuff == null)
				return;
			buffEntity.reduceEffectTimes();
			float rate = NumberUtils.toFloat(battleBuff.getBuffsAcquireRateFormula(), 0.f);
			if (!RandomUtils.baseRandomHit(rate))
				return;
			int round = NumberUtils.toInt(battleBuff.getBuffsPersistRoundFormula(), 0);
			if (round <= 0)
				return;
			BattleBuffEntity buf = new BattleBuffEntity(battleBuff, currentSoldier, s, buffEntity.skillId(), round);
			if (s.buffHolder().addBuff(buf))
				commandContext.skillAction().addTargetState(new VideoBuffAddTargetState(buf));
		});
	}

	private static int[] leftRightPos(int pos) {
		int[] hit = new int[2];
		for (int i = 0; i < positions.length; i++) {
			int[] arr = positions[i];
			for (int j = 0; j < arr.length; j++) {
				if (arr[j] == pos) {
					if (j > 0)
						hit[0] = arr[j - 1];
					if (j < arr.length - 1)
						hit[1] = arr[j + 1];
					break;
				}
			}
		}
		return hit;
	}
}
