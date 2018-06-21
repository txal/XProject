/**
 * 
 */
package com.nucleus.logic.core.modules.battle.dto;

import org.apache.commons.lang3.builder.ReflectionToStringBuilder;
import org.apache.commons.lang3.builder.ToStringStyle;

import com.nucleus.logic.core.modules.battle.model.BattleSoldier;

/**
 * @author hwy
 * 
 */
public class VideoActionTargetSkillState extends VideoTargetState {
	public VideoActionTargetSkillState() {
	}

	public VideoActionTargetSkillState(BattleSoldier target, int skillId) {
		super(target);
		this.skillId = skillId;
	}

	/** 技能编号 */
	private int skillId;

	public int getSkillId() {
		return skillId;
	}

	public void setSkillId(int skillId) {
		this.skillId = skillId;
	}

	@Override
	public String toString() {
		return ReflectionToStringBuilder.toString(this, ToStringStyle.SHORT_PREFIX_STYLE);
	}
}
