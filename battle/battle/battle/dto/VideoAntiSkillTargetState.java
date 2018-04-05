/**
 * 
 */
package com.nucleus.logic.core.modules.battle.dto;

import com.nucleus.logic.core.modules.battle.model.BattleSoldier;

/**
 * 技能免疫
 * 
 * @author wgy
 * 
 */
public class VideoAntiSkillTargetState extends VideoTargetState {
	public VideoAntiSkillTargetState() {
	}

	public VideoAntiSkillTargetState(BattleSoldier target) {
		super(target);
	}
}
