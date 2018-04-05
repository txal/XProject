package com.nucleus.logic.core.modules.battle.dto;

import java.util.Set;

import com.nucleus.logic.core.modules.battle.model.BattleSoldier;

/**
 * 撤退
 * 
 * @author wgy
 *
 */
public class VideoRetreatState extends VideoTargetState {
	/**
	 * 撤退是否成功
	 */
	private boolean success;
	/**
	 * 撤退成功率
	 */
	private float rate;
	/**
	 * 该单位撤退时，需要一同撤退的其他单位
	 */
	private Set<Long> retreatSoldiers;

	public VideoRetreatState() {
	}

	public VideoRetreatState(BattleSoldier soldier, boolean success, float rate) {
		super(soldier);
		this.success = success;
		this.rate = rate;
	}

	public boolean isSuccess() {
		return success;
	}

	public void setSuccess(boolean success) {
		this.success = success;
	}

	public float getRate() {
		return rate;
	}

	public void setRate(float rate) {
		this.rate = rate;
	}

	public Set<Long> getRetreatSoldiers() {
		return retreatSoldiers;
	}

	public void setRetreatSoldiers(Set<Long> retreatSoldiers) {
		this.retreatSoldiers = retreatSoldiers;
	}
}
