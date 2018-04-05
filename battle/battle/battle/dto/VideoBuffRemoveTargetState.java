/**
 * 
 */
package com.nucleus.logic.core.modules.battle.dto;

import org.apache.commons.lang3.ArrayUtils;

import com.nucleus.logic.core.modules.battle.model.BattleSoldier;

/**
 * @author Omanhom
 * 
 */
public class VideoBuffRemoveTargetState extends VideoTargetState {
	/** 清除的buff编号 */
	private int[] buffId;

	public VideoBuffRemoveTargetState() {
	}

	public VideoBuffRemoveTargetState(BattleSoldier target, int... buffId) {
		super(target);
		this.buffId = buffId;
	}

	public VideoBuffRemoveTargetState(BattleSoldier target, Integer[] buffIds) {
		super(target);
		this.buffId = ArrayUtils.toPrimitive(buffIds);
	}

	public int[] getBuffId() {
		return buffId;
	}

	public void setBuffId(int[] buffId) {
		this.buffId = buffId;
	}
}
