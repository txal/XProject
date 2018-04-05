/**
 * 
 */
package com.nucleus.logic.core.modules.battlebuff;

import java.util.Map;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.dto.VideoActionTargetState;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;

/**
 * 影响气血上限buff删除处理
 * 
 * @author hwy
 *
 */
@Service
public class BattleBuffLogic_24 extends BattleBuffLogicAdapter {

	@Override
	public void onRemove(BattleBuffEntity buffEntity) {
		Map<String, Object> meta = buffEntity.getBattleMeta();
		if (meta.isEmpty() || !meta.containsKey("maxHp"))
			return;
		BattleSoldier target = buffEntity.getEffectSoldier();

		// 当前属性
		float curHpRate = target.hpRate();

		// 恢复后属性
		int maxHp = (Integer) meta.getOrDefault("maxHp", 0);
		int hp = (int) Math.floor(maxHp * curHpRate);
		int addHp = hp - target.hp() <= 0 ? 0 : hp - target.hp();

		target.battleBaseProperties().setMaxHp(maxHp);
		target.increaseHp(addHp);
		target.currentVideoRound().endAction().addTargetState(new VideoActionTargetState(target, addHp, 0, false, 0, 0, maxHp));
		// 删除原气血上限
		meta.remove("maxHp");
	}
}
