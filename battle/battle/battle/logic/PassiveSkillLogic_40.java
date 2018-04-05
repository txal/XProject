package com.nucleus.logic.core.modules.battle.logic;

import java.util.HashSet;
import java.util.Set;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.dto.VideoAction;
import com.nucleus.logic.core.modules.battle.dto.VideoBuffRemoveTargetState;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 移除队伍buff
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLogic_40 extends AbstractPassiveSkillLogic {
	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		Set<Integer> buffIdSet = soldier.battleTeam().getTeamBuffIds();
		if (buffIdSet.isEmpty())
			return;
		VideoAction videoAction = null;
		if (context != null) {
			videoAction = context.skillAction();
		} else if (target != null) {// target==攻击者
			videoAction = target.getCommandContext().skillAction();
		} else {
			videoAction = soldier.currentVideoRound().endAction();
		}
		for (BattleSoldier member : soldier.battleTeam().soldiersMap().values()) {
			Set<Integer> removed = new HashSet<>();
			for (int buffId : buffIdSet) {
				if (member.buffHolder().removeBuffById(buffId) != null)
					removed.add(buffId);
			}
			if (!removed.isEmpty())
				videoAction.addTargetState(new VideoBuffRemoveTargetState(member, removed.toArray(new Integer[] {})));
		}
		buffIdSet.clear();
	}
}
