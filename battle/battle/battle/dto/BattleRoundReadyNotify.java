package com.nucleus.logic.core.modules.battle.dto;

import com.nucleus.commons.message.BroadcastMessage;
/**
 * 回合准备通知
 * @author wgy
 *
 */
public class BattleRoundReadyNotify implements BroadcastMessage {
	private int round;

	public BattleRoundReadyNotify() {}
	
	public BattleRoundReadyNotify(int round) {
		this.round = round;
	}
	public int getRound() {
		return round;
	}

	public void setRound(int round) {
		this.round = round;
	}

}
