package com.nucleus.logic.core.modules.battle.logic;

import org.apache.commons.lang3.builder.ReflectionToStringBuilder;
import org.apache.commons.lang3.builder.ToStringStyle;

public class SkillTargetInfo {

	/** 第n个目标 */
	private int targetNum;

	/** 技能所需门派技能等级/自身等级 */
	private int skillPreqLevel;

	/** 攻击力加成百分比 */
	private float attackVaryRate;

	/** 伤害效果百分比 */
	private float damageVaryRate;

	public int getTargetNum() {
		return targetNum;
	}

	public void setTargetNum(int targetNum) {
		this.targetNum = targetNum;
	}

	public int getSkillPreqLevel() {
		return skillPreqLevel;
	}

	public void setSkillPreqLevel(int skillPreqLevel) {
		this.skillPreqLevel = skillPreqLevel;
	}

	public float getAttackVaryRate() {
		return attackVaryRate;
	}

	public void setAttackVaryRate(float attackVaryRate) {
		this.attackVaryRate = attackVaryRate;
	}

	public float getDamageVaryRate() {
		return damageVaryRate;
	}

	public void setDamageVaryRate(float damageVaryRate) {
		this.damageVaryRate = damageVaryRate;
	}

	@Override
	public String toString() {
		return ReflectionToStringBuilder.toString(this, ToStringStyle.SHORT_PREFIX_STYLE);
	}

}
