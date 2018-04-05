package com.nucleus.logic.core.modules.battle.data;

import org.apache.commons.lang3.builder.ReflectionToStringBuilder;
import org.apache.commons.lang3.builder.ToStringStyle;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.commons.message.GeneralResponse;

/**
 * 技能权重信息
 * 
 * @author liguo
 * 
 */
@GenIgnored
public class SkillWeightInfo extends GeneralResponse {

	/** 技能编号 */
	private int skillId;

	/** 技能权重 */
	private int skillWeight;

	public SkillWeightInfo() {
	}

	public Skill skill() {
		return Skill.get(this.getSkillId());
	}

	public SkillWeightInfo(int skillId, int skillWeight) {
		this.skillId = skillId;
		this.skillWeight = skillWeight;
	}

	public int getSkillId() {
		return skillId;
	}

	public int getSkillWeight() {
		return skillWeight;
	}

	public void setSkillId(int skillId) {
		this.skillId = skillId;
	}

	public void setSkillWeight(int skillWeight) {
		this.skillWeight = skillWeight;
	}

	@Override
	public String toString() {
		return ReflectionToStringBuilder.toString(this, ToStringStyle.SHORT_PREFIX_STYLE);
	}

}
