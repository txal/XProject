package com.nucleus.logic.core.modules.battle.data;

import java.util.HashSet;
import java.util.Set;

import com.nucleus.commons.utils.RandomUtils;
import com.nucleus.logic.core.modules.battle.BattleUtils;

/**
 * 反击信息
 * 
 * @author liguo
 * 
 */
public class StrikeBackInfo {

	/** 反击概率 */
	private float strikeBackSuccessRate;

	/** 反击伤害变动率 */
	private float strikeBackDamageVaryRate;

	/** 反击技能权重 */
	private SkillsWeight skillsWeight;
	/**
	 * 被反击技能集合
	 */
	private Set<Integer> beStrikeBackSkillIds = new HashSet<Integer>();

	public StrikeBackInfo() {
	}

	public StrikeBackInfo(SkillsWeight skillsWeight, float strikeBackRate, float strikeBackDamageVaryRate, Set<Integer> beStrikeBackSkillIds) {
		this.skillsWeight = skillsWeight;
		this.strikeBackSuccessRate = strikeBackRate;
		this.strikeBackDamageVaryRate = strikeBackDamageVaryRate;
		if (beStrikeBackSkillIds != null)
			this.beStrikeBackSkillIds.addAll(beStrikeBackSkillIds);
	}

	public Skill strikeBackSkill() {
		return Skill.get(BattleUtils.randomActiveSkillId(skillsWeight));
	}

	public boolean hasStrikeBack() {
		return RandomUtils.baseRandomHit(strikeBackSuccessRate);
	}

	public float strikeBackDamageVaryRate() {
		return strikeBackDamageVaryRate;
	}

	public SkillsWeight skillsWeight() {
		return skillsWeight;
	}

	public Set<Integer> getBeStrikeBackSkillIds() {
		return beStrikeBackSkillIds;
	}

	public void setBeStrikeBackSkillIds(Set<Integer> beStrikeBackSkillIds) {
		this.beStrikeBackSkillIds = beStrikeBackSkillIds;
	}

}
