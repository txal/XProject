package com.nucleus.logic.core.modules.battle.model;

import java.util.Map;

import com.nucleus.commons.data.StaticConfig;
import com.nucleus.logic.core.modules.AppStaticConfigs;
import com.nucleus.logic.core.modules.arena.data.ArenaPositionConfig;
import com.nucleus.logic.core.modules.battle.dto.PvpTypeEnum;
import com.nucleus.logic.core.modules.scene.model.ScenePoint;

/**
 * 擂台挑战
 * 
 * @author wgy
 *
 */
public class ArenaBattle extends PvpBattle {

	public ArenaBattle(BattlePlayer p1, BattlePlayer p2) {
		super(p1, p2);
	}

	@Override
	protected void initTeamPlayers(BattlePlayer player, Map<Long, BattlePlayer> players) {
		players.put(player.getId(), player);
		// 只有在组队状态并且没有离队才拉其他同队玩家进来
		if (player.ifInTeam()) {
			for (BattlePlayer teamPlayer : player.teamBattlePlayers()) {
				if (teamPlayer.getId() == player.getId())
					continue;
				players.put(teamPlayer.getId(), teamPlayer);
			}
		}
	}

	@Override
	protected void battleFinish(BattleTeam winTeam, BattleTeam loseTeam) {
		super.battleFinish(winTeam, loseTeam);
		// 平局
		if (winTeam == null || loseTeam == null)
			return;
		ScenePoint point = ArenaPositionConfig.random();
		if (point != null) {
			BattlePlayer leader = loseTeam.leader();
			leader.currentScene().deliver(leader.getId(), point.getX(), point.getZ());
		}
	}

	@Override
	public float retreatSuccessRate() {
		return StaticConfig.get(AppStaticConfigs.ARENA_RETREAT_SUCCESS_RATE).getAsFloat(0.7f);
	}

	@Override
	public int getType() {
		return PvpTypeEnum.Arena.ordinal();
	}

}
