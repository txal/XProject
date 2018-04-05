package com.nucleus.logic.core.modules.battlebuff.model;

import com.nucleus.commons.annotation.GenIgnored;

/**
 * 影响反击伤害变动率
 * 
 * @author wangyu
 *
 */
@GenIgnored
public class BuffLogicParam_35 extends BuffLogicParam {
	/** 伤害变动率公式 */
	String damageVaryRate;
	/** 触发该buff 的技能编号 */
	int skillId;

	public String getDamageVaryRate() {
		return damageVaryRate;
	}

	public void setDamageVaryRate(String damageVaryRate) {
		this.damageVaryRate = damageVaryRate;
	}

	public int getSkillId() {
		return skillId;
	}

	public void setSkillId(int skillId) {
		this.skillId = skillId;
	}

}
