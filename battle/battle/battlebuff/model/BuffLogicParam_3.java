package com.nucleus.logic.core.modules.battlebuff.model;

import com.nucleus.commons.annotation.GenIgnored;

/**
 * 忽略指令,随机攻击
 * 
 * @author wgy
 *
 */
@GenIgnored
public class BuffLogicParam_3 extends BuffLogicParam {
	/** 目标过滤逻辑 */
	private int aiLogicId;
	/** 选择目标逻辑 */
	private int selectTargetLogicId;

	public int getAiLogicId() {
		return aiLogicId;
	}

	public void setAiLogicId(int aiLogicId) {
		this.aiLogicId = aiLogicId;
	}

	public int getSelectTargetLogicId() {
		return selectTargetLogicId;
	}

	public void setSelectTargetLogicId(int selectTargetLogicId) {
		this.selectTargetLogicId = selectTargetLogicId;
	}
}
