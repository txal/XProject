package com.nucleus.logic.core.modules.battle.data;

import com.nucleus.commons.annotation.IncludeEnum;
import com.nucleus.commons.annotation.IncludeEnums;

/**
 * 装备技能
 * 
 * @author wgy
 *
 */
@IncludeEnums({ @IncludeEnum(PetSkillTypeEnum.class) })
public class EquipmentSkill extends Skill {
	/**
	 * PetSkillTypeEnum
	 */
	private int type;

	public int getType() {
		return type;
	}

	public void setType(int type) {
		this.type = type;
	}
}
