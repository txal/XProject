package com.nucleus.logic.core.modules.battle.logic;

import java.util.Set;

import org.springframework.stereotype.Service;

import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.battle.data.Monster;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.dto.VideoRetreatState;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.BattleTeam;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.faction.data.Faction;

/**
 * 魅：如果玩家队伍里面有方寸山、盘丝洞、普陀山、化生寺门派，则第一回合开始自动逃跑且100%成功，如果不存在上述门派则在第二回合末逃跑且100%成功
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLogic_36 extends AbstractPassiveSkillLogic {
	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		if (!super.launchable(soldier, target, context, config, timing, passiveSkill))
			return false;
		if (soldier.isDead())
			return false;
		if (!(soldier.battleUnit() instanceof Monster))
			return false;
		Monster m = (Monster) soldier.battleUnit();
		if (!m.isMei())
			return false;
		if (soldier.battle().getCount() == 1) {
			if (config.getExtraParams() == null || config.getExtraParams().length <= 0)
				return false;
			Set<Integer> factionIds = SplitUtils.split2IntSet(config.getExtraParams()[0], ",");
			BattleTeam enemyTeam = soldier.battleTeam().getEnemyTeam();
			for (BattleSoldier s : enemyTeam.soldiersMap().values()) {
				Faction f = s.faction();
				if (f == null)
					continue;
				if (factionIds.contains(f.getId()))
					return true;
			}
		} else
			return true;
		return false;
	}

	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		soldier.leaveTeam();
		if (timing == PassiveSkillLaunchTimingEnum.RoundOver)
			soldier.currentVideoRound().endAction().addTargetState(new VideoRetreatState(soldier, true, 1));
		else
			soldier.currentVideoRound().readyAction().addTargetState(new VideoRetreatState(soldier, true, 1));
	}
}
