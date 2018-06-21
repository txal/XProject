package com.nucleus.logic.core.modules.battlebuff;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.dto.VideoCallSoldierLeaveState;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.BattleTeam;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;

/**
 * 召唤出来的宠物会附加一个特殊buff,该buff结束的时候会移除相关的soldier
 * 
 * @author wgy
 *
 */
@Service
public class BattleBuffLogic_2 extends BattleBuffLogicAdapter {
	@Override
	public void onRemove(BattleBuffEntity buffEntity) {
		BattleSoldier soldier = buffEntity.getEffectSoldier();
		BattleTeam team = soldier.battleTeam();
		soldier.leaveTeam();
		team.getCalledMonsters().remove(soldier.getId());
		buffEntity.getEffectSoldier().currentVideoRound().endAction().addTargetState(new VideoCallSoldierLeaveState(soldier));
	}
}
