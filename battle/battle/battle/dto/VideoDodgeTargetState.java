/**
 * 
 */
package com.nucleus.logic.core.modules.battle.dto;

import com.nucleus.logic.core.modules.battle.model.BattleSoldier;

/**
 * 闪避状态
 * 
 * @author Omanhom
 * 
 */
public class VideoDodgeTargetState extends VideoTargetState {
	public VideoDodgeTargetState() {
	}

	public VideoDodgeTargetState(BattleSoldier target) {
		super(target);
	}
}
