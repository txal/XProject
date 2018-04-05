package com.nucleus.logic.core.modules.battle.data;

import com.nucleus.commons.data.StaticDataManager;
import com.nucleus.logic.core.modules.battle.logic.IPassiveSkill;

/**
 * 坐骑门派被动技能
 *
 * @author zhanhua.xu
 */
public class MountFactionPassiveSkill extends MountSkill implements IPassiveSkill {
	public static MountFactionPassiveSkill get(int id) {
		return StaticDataManager.getInstance().get(MountFactionPassiveSkill.class, id);
	}

	public enum MountFactionLevel {
		Unknow,
		/** 低级 */
		Low,
		/** 中级 */
		Middle,
		/** 高级 */
		High
	}

	/** 门派编号 */
	private int factionId;
	/** 消耗点数 */
	private int spendAmt;
	/** 先要学习的技能编号 */
	private int preSkillId;
	/** 技能配置 */
	private int[] configId;
	private int type;
	/** MountFactionLevel 1初，2中，3高 */
	private int levelType;

	@Override
	public int getType() {
		return type;
	}

	public void setType(int type) {
		this.type = type;
	}

	public int getFactionId() {
		return factionId;
	}

	public void setFactionId(int factionId) {
		this.factionId = factionId;
	}

	public int getSpendAmt() {
		return spendAmt;
	}

	public void setSpendAmt(int spendAmt) {
		this.spendAmt = spendAmt;
	}

	@Override
	public int[] getConfigId() {
		return configId;
	}

	public void setConfigId(int[] configId) {
		this.configId = configId;
	}

	public int getPreSkillId() {
		return preSkillId;
	}

	public void setPreSkillId(int preSkillId) {
		this.preSkillId = preSkillId;
	}

	public MountFactionPassiveSkill preSkill() {
		return MountFactionPassiveSkill.get(this.preSkillId);
	}

	public int getLevelType() {
		return levelType;
	}

	public void setLevelType(int levelType) {
		this.levelType = levelType;
	}

}
