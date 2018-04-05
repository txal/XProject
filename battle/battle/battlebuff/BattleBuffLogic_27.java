/**
 * 
 */
package com.nucleus.logic.core.modules.battlebuff;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.dto.VideoBuffRemoveTargetState;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;

/**
 * buff释放者死亡或者离场就移除buff
 * 
 * @author hwy
 *
 */
@Service
public class BattleBuffLogic_27 extends BattleBuffLogicAdapter {

	@Override
	public void onRoundEnd(BattleBuffEntity buffEntity) {
		BattleSoldier trigger = buffEntity.getTriggerSoldier();
		if (trigger == null || trigger.isDead() || trigger.isLeave()) {
			BattleSoldier target = buffEntity.getEffectSoldier();
			int buffId = buffEntity.battleBuffId();
			target.buffHolder().removeBuffById(buffId);
			buffEntity.getEffectSoldier().currentVideoRound().endAction().addTargetState(new VideoBuffRemoveTargetState(target, buffId));
		}
	}
}
