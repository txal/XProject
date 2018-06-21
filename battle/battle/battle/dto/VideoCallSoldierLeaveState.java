package com.nucleus.logic.core.modules.battle.dto;

import com.nucleus.logic.core.modules.battle.model.BattleSoldier;

/**
 * 召唤出来的小怪消失
 * 
 * @author wgy
 *
 */
public class VideoCallSoldierLeaveState extends VideoTargetState {

	public VideoCallSoldierLeaveState() {
	}

	public VideoCallSoldierLeaveState(BattleSoldier soldier) {
		super(soldier);
	}
}
