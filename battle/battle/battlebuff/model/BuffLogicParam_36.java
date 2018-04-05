package com.nucleus.logic.core.modules.battlebuff.model;

import com.nucleus.commons.annotation.GenIgnored;

/**
 * 
 * @author wgy
 *
 */
@GenIgnored
public class BuffLogicParam_36 extends BuffLogicParam {
	/** 传染的buff 编号 */
	private int buffId;
	/** 相关技能编号 */
	private int skillId;
	/** 概率公式 */
	private String rate;

	public int getBuffId() {
		return buffId;
	}

	public void setBuffId(int buffId) {
		this.buffId = buffId;
	}

	public int getSkillId() {
		return skillId;
	}

	public void setSkillId(int skillId) {
		this.skillId = skillId;
	}

	public String getRate() {
		return rate;
	}

	public void setRate(String rate) {
		this.rate = rate;
	}

}
