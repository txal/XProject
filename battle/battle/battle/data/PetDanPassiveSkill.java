package com.nucleus.logic.core.modules.battle.data;

import com.nucleus.logic.core.modules.battle.logic.IPassiveSkill;

/**
 * 内丹被动技能
 * 
 * @author yifan.chen
 *
 */
public class PetDanPassiveSkill extends PetPassiveSkill implements IPassiveSkill {
	/** 效果公式客户端用 **/
	private String effectFormula;

	public String getEffectFormula() {
		return effectFormula;
	}

	public void setEffectFormula(String effectFormula) {
		this.effectFormula = effectFormula;
	}
}
