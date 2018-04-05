/**
 * 
 */
package com.nucleus.logic.core.modules.battle.dto;

import org.apache.commons.lang3.builder.ReflectionToStringBuilder;
import org.apache.commons.lang3.builder.ToStringStyle;

import com.nucleus.commons.message.BroadcastMessage;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;

/**
 * @author Omanhom
 * 
 */
public abstract class VideoTargetState implements BroadcastMessage {
	public VideoTargetState() {
	}

	public VideoTargetState(BattleSoldier target) {
		this.id = target.getId();
		this.dead = target.isDead();
		this.leave = target.isLeave();
	}

	/** 动作目标编号 */
	private long id;
	/** 是否死亡 */
	private boolean dead;
	/**
	 * 死亡后是否离开战场,某些情况下死亡后不离开,等待复活,默认要离开
	 */
	private boolean leave = true;

	public long getId() {
		return id;
	}

	public void setId(long id) {
		this.id = id;
	}

	public boolean isDead() {
		return dead;
	}

	public void setDead(boolean dead) {
		this.dead = dead;
	}

	public boolean isLeave() {
		return leave;
	}

	public void setLeave(boolean leave) {
		this.leave = leave;
	}

	@Override
	public String toString() {
		return ReflectionToStringBuilder.toString(this, ToStringStyle.SHORT_PREFIX_STYLE);
	}

	@Override
	public int hashCode() {
		final int prime = 31;
		int result = 1;
		result = (int) (prime * result + id);
		return result;
	}

	@Override
	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;
		VideoTargetState other = (VideoTargetState) obj;
		if (id <= 0) {
			if (other.id > 0)
				return false;
		} else if (id == other.id)
			return false;
		return true;
	}
}
