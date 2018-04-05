/**
 * 
 */
package com.nucleus.logic.core.modules.battle.dto;

import org.apache.commons.lang3.builder.ReflectionToStringBuilder;
import org.apache.commons.lang3.builder.ToStringStyle;

import com.nucleus.logic.core.modules.battle.model.BattleSoldier;

/**
 * @author liguo
 * 
 */
public class VideoSwtichPetState extends VideoTargetState {

	/** 替换宠物 */
	private VideoSoldier switchPetSoldier;

	public VideoSwtichPetState() {
	}

	public VideoSwtichPetState(BattleSoldier switchPet) {
		this.setSwitchPetSoldier(new VideoSoldier(switchPet));
	}

	@Override
	public String toString() {
		return ReflectionToStringBuilder.toString(this, ToStringStyle.SHORT_PREFIX_STYLE);
	}

	public VideoSoldier getSwitchPetSoldier() {
		return switchPetSoldier;
	}

	public void setSwitchPetSoldier(VideoSoldier switchPetSoldier) {
		this.switchPetSoldier = switchPetSoldier;
	}
}
