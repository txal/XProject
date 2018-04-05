package com.nucleus.logic.core.modules.battle.event;

import com.nucleus.player.event.PlayerEvent;

/**
 * 战斗事件基础类
 *
 * Created by Tony on 15/7/14.
 */
public class BattleEvent extends PlayerEvent {

	private long playerId;

	private Object evtMessage;

	public BattleEvent() {
	}

	public BattleEvent(long playerId, Object evtMessage) {
		this.playerId = playerId;
		this.evtMessage = evtMessage;
	}

	public static BattleEvent wrap(long playerId, Object evtMessage) {
		return new BattleEvent(playerId, evtMessage);
	}

	public Object getEvtMessage() {
		return evtMessage;
	}

	public void setEvtMessage(Object evtMessage) {
		this.evtMessage = evtMessage;
	}

	public long getPlayerId() {
		return playerId;
	}

	public void setPlayerId(long playerId) {
		this.playerId = playerId;
	}
}
