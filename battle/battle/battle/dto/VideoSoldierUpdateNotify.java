package com.nucleus.logic.core.modules.battle.dto;

import java.util.ArrayList;
import java.util.List;

import com.nucleus.commons.message.BroadcastMessage;

/**
 * 战斗单位更新通知
 * 
 * @author wgy
 *
 */
public class VideoSoldierUpdateNotify implements BroadcastMessage {
	private List<VideoSoldier> soldiers = new ArrayList<VideoSoldier>();

	public List<VideoSoldier> getSoldiers() {
		return soldiers;
	}

	public void setSoldiers(List<VideoSoldier> soldiers) {
		this.soldiers = soldiers;
	}

}
