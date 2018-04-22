package com.nucleus.logic.core.modules.battle.dto;

import java.util.HashSet;
import java.util.Set;

import com.nucleus.commons.message.BroadcastMessage;

/**
 * 进入战斗下发场景其他玩家
 * 
 * @author liguo
 * 
 */
public class BattleSceneNotify implements BroadcastMessage {

	/** 队长玩家编号 */
	private Set<Long> leaderPlayerIds;

	/** 是否战斗 */
	private boolean inBattle;

	public BattleSceneNotify() {
	}

	public BattleSceneNotify(boolean inBattle, long... leaderPlayerIds) {
		if (null != leaderPlayerIds) {
			this.setLeaderPlayerIds(new HashSet<Long>());
			for (int i = 0; i < leaderPlayerIds.length; i++) {
				long leaderPlayerId = leaderPlayerIds[i];
				if (leaderPlayerId < 1) {
					continue;
				}
				this.getLeaderPlayerIds().add(leaderPlayerIds[i]);
			}
		}
		this.setInBattle(inBattle);
	}

	public BattleSceneNotify(boolean inBattle, Set<Long> leaderPlayerIds) {
		this.setInBattle(inBattle);
		this.setLeaderPlayerIds(leaderPlayerIds);
	}

	public boolean isInBattle() {
		return inBattle;
	}

	public void setInBattle(boolean inBattle) {
		this.inBattle = inBattle;
	}

	public Set<Long> getLeaderPlayerIds() {
		return leaderPlayerIds;
	}

	public void setLeaderPlayerIds(Set<Long> leaderPlayerIds) {
		this.leaderPlayerIds = leaderPlayerIds;
	}

}
