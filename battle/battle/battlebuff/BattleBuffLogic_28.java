/**
 * 
 */
package com.nucleus.logic.core.modules.battlebuff;

import java.util.Map;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.dto.VideoBuffRemoveTargetState;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;

/**
 * 受击后减少buff触发次数
 * 
 * @author hwy
 *
 */
@Service
public class BattleBuffLogic_28 extends BattleBuffLogicAdapter {

	@Override
	public void underAttack(CommandContext commandContext, BattleBuffEntity buffEntity) {
		String key = "buffCount";
		Map<String, Object> meta = buffEntity.getBattleMeta();
		int buffCount = (Integer) meta.getOrDefault(key, buffEntity.battleBuff().getBuffsEffectTimes());
		buffCount -= 1;
		if (buffCount <= 0) {
			meta.remove(key);
			BattleSoldier target = buffEntity.getEffectSoldier();
			int buffId = buffEntity.battleBuffId();
			target.buffHolder().removeBuffById(buffId);
			commandContext.skillAction().addTargetState(new VideoBuffRemoveTargetState(target, buffId));
		} else {
			meta.put(key, buffCount);
		}
	}
}
