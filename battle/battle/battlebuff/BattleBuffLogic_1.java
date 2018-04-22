package com.nucleus.logic.core.modules.battlebuff;

import java.util.Iterator;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.dto.VideoActionTargetState;
import com.nucleus.logic.core.modules.battle.dto.VideoTargetState;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;

/**
 * 后发制人技能触发休息buff,行动结束后移除技能目标(客户端表现为不打敌人) 2016-04-21:调整技能目标为自己
 * 
 * @author wgy
 *
 */
@Service
public class BattleBuffLogic_1 extends BattleBuffLogicAdapter {
	@Override
	public void onActionEnd(CommandContext commandContext, BattleBuffEntity buffEntity) {
		Iterator<VideoTargetState> it = commandContext.skillAction().targetStates().iterator();
		while (it.hasNext()) {
			VideoTargetState state = it.next();
			if (state instanceof VideoActionTargetState) {
				BattleSoldier trigger = commandContext.trigger();
				if (state.getId() != trigger.id()) {
					VideoActionTargetState s = (VideoActionTargetState) state;
					s.setId(trigger.id());
					s.setCrit(false);
					s.setCurrentHp(trigger.hp());
					s.setCurrentSp(trigger.getSp());
					s.setDead(false);
					s.setHp(0);
					s.setLeave(false);
					s.setMp(0);
					s.setSp(0);
					break;
				}
			}
		}
	}
}
