/**
 * 
 */
package com.nucleus.logic.core.modules.battle.data;

import org.apache.commons.lang3.builder.ReflectionToStringBuilder;
import org.apache.commons.lang3.builder.ToStringStyle;

import com.nucleus.commons.data.DataBasic;
import com.nucleus.commons.data.StaticDataManager;
import com.nucleus.commons.message.BroadcastMessage;
import com.nucleus.logic.core.modules.battle.logic.SkillAiLogic;
import com.nucleus.logic.core.modules.battle.manager.SkillAiLogicManager;

/**
 * 技能目标AI
 * 
 * @author Omanhom
 * 
 */
public class SkillAi implements BroadcastMessage, DataBasic {
	public static SkillAi get(int id) {
		return StaticDataManager.getInstance().get(SkillAi.class, id);
	}

	public void afterPropertySet() {

	}

	private int id;
	private String name;
	private String description;

	public int getId() {
		return id;
	}

	public void setId(int id) {
		this.id = id;
	}

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public String getDescription() {
		return description;
	}

	public void setDescription(String description) {
		this.description = description;
	}

	public SkillAiLogic skillAiLogic() {
		SkillAiLogic skillAiLogic = SkillAiLogicManager.getInstance().getLogic(id);
		return skillAiLogic;
	}

	@Override
	public String toString() {
		return ReflectionToStringBuilder.toString(this, ToStringStyle.SHORT_PREFIX_STYLE);
	}
}
