/**
 * 
 */
package com.nucleus.logic.core.modules.battlebuff.model;

import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff.BattleBasePropertyType;

/**
 * buff数据
 * 
 * @author liguo
 * 
 */
public class BattleBuffContext {

	/** 所属战斗buff编号 */
	private int battleBuffId;

	/** 战斗基础属性类型 */
	private BattleBasePropertyType battleBasePropertyType;

	/** 战斗基础属性效果公式 */
	private String battleBasePropertyEffectFormula;

	public BattleBuffContext() {

	}

	public BattleBuffContext(int battleBuffId, BattleBasePropertyType battleBasePropertyType, String battleBasePropertyEffectFormula) {
		this.battleBuffId = battleBuffId;
		this.battleBasePropertyType = battleBasePropertyType;
		this.battleBasePropertyEffectFormula = battleBasePropertyEffectFormula;
	}

	public int battleBuffId() {
		return battleBuffId;
	}

	public BattleBasePropertyType battleBasePropertyType() {
		return battleBasePropertyType;
	}

	public String battleBasePropertyEffectFormula() {
		return battleBasePropertyEffectFormula;
	}

}
