package com.nucleus.logic.core.modules.battle.dto;

import com.nucleus.commons.message.BroadcastMessage;

/**
 * 退出观战通知
 * <p>
 * Created by Tony on 15/6/23.
 */
public class BattleWatchExit implements BroadcastMessage {

	/**
	 * 退出的战斗id *
	 */
	private long battleId;

	public BattleWatchExit() {
	}

	public BattleWatchExit(long battleId) {
		this.battleId = battleId;
	}

	public long getBattleId() {
		return battleId;
	}

	public void setBattleId(long battleId) {
		this.battleId = battleId;
	}
}
