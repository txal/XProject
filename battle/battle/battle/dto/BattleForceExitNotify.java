/**
 * 
 */
package com.nucleus.logic.core.modules.battle.dto;

import com.nucleus.commons.message.BroadcastMessage;

/**
 * 客户端收到后，出提示信息并退出战斗
 * 
 * @author zhanhua.xu
 */
public class BattleForceExitNotify implements BroadcastMessage {
	/**
	 * 退出的战斗id *
	 */
	private long battleId;

	public long getBattleId() {
		return battleId;
	}

	public void setBattleId(long battleId) {
		this.battleId = battleId;
	}

	public BattleForceExitNotify() {
	}

	public BattleForceExitNotify(long battleId) {
		this.battleId = battleId;
	}

}
