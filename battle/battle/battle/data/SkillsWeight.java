package com.nucleus.logic.core.modules.battle.data;

import java.util.List;

import org.apache.commons.lang3.builder.ReflectionToStringBuilder;
import org.apache.commons.lang3.builder.ToStringStyle;

import com.nucleus.logic.core.modules.battle.BattleUtils;

/**
 * 技能权重信息
 * 
 * @author liguo
 * 
 */
public class SkillsWeight {

	/** 权重范围 */
	private int skillsWeightScope;

	/** 技能权重信息列表 */
	private List<SkillWeightInfo> skillWeightInfos;

	public SkillsWeight() {
	}

	public SkillsWeight(int skillsWeightScope, List<SkillWeightInfo> skillWeightInfos) {
		this.skillsWeightScope = skillsWeightScope;
		this.skillWeightInfos = skillWeightInfos;
	}

	public int randomeSkillId() {
		return BattleUtils.randomActiveSkillId(this);
	}

	public int skillsWeightScope() {
		return skillsWeightScope;
	}

	public List<SkillWeightInfo> skillWeightInfos() {
		return skillWeightInfos;
	}

	@Override
	public String toString() {
		return ReflectionToStringBuilder.toString(this, ToStringStyle.SHORT_PREFIX_STYLE);
	}
}
