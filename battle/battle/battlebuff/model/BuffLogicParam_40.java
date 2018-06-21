package com.nucleus.logic.core.modules.battlebuff.model;

import com.nucleus.commons.annotation.GenIgnored;

/**
 * 根据技能等级反弹伤害并减少作用次数
 * 
 * @author wangyu
 *
 */
@GenIgnored
public class BuffLogicParam_40 extends BuffLogicParam {

	/** 技能编号 */
	private int skillId;
	/** 百分比公式 */
	private String reboundDamage;

	public int getSkillId() {
		return skillId;
	}

	public void setSkillId(int skillId) {
		this.skillId = skillId;
	}

	public String getReboundDamage() {
		return reboundDamage;
	}

	public void setReboundDamage(String reboundDamage) {
		this.reboundDamage = reboundDamage;
	}

}
