package com.nucleus.logic.core.modules.battle.data;

import com.nucleus.commons.data.DataId;
import com.nucleus.commons.message.BroadcastMessage;

/**
 * 技能信息
 * 
 * @author liguo
 * 
 */
public class SkillInfo implements BroadcastMessage {

	/** 技能编号 */
	@DataId(Skill.class)
	private int skillId;

	/** 可掌握门派技能等级 */
	private int acquireFactionSkillLevel;

	public SkillInfo() {
	}

	public SkillInfo(int skillId, int acquireFactionSkillLevel) {
		this.setSkillId(skillId);
		this.setAcquireFactionSkillLevel(acquireFactionSkillLevel);
	}

	public int getSkillId() {
		return skillId;
	}

	public void setSkillId(int skillId) {
		this.skillId = skillId;
	}

	public int getAcquireFactionSkillLevel() {
		return acquireFactionSkillLevel;
	}

	public void setAcquireFactionSkillLevel(int acquireFactionSkillLevel) {
		this.acquireFactionSkillLevel = acquireFactionSkillLevel;
	}

}
