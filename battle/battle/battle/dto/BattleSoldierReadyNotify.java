package com.nucleus.logic.core.modules.battle.dto;

import com.nucleus.commons.message.BroadcastMessage;

/**
 * 主角/宠物准备就绪通知
 * 
 * @author wgy
 *
 */
public class BattleSoldierReadyNotify implements BroadcastMessage {
	/**
	 * 角色唯一id
	 */
	private long soldierId;

	public BattleSoldierReadyNotify() {
	}

	public BattleSoldierReadyNotify(long soldierId) {
		this.soldierId = soldierId;
	}

	public long getSoldierId() {
		return soldierId;
	}

	public void setSoldierId(long soldierId) {
		this.soldierId = soldierId;
	}
}
