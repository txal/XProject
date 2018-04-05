package com.nucleus.logic.core.modules.battle.dto;

import com.nucleus.logic.core.modules.battle.model.BattleSoldier;

/**
 * 对目标偷钱动作
 * 
 * @author wgy
 *
 */
public class VideoActionStealTargetState extends VideoTargetState {
	private int skillId;
	/** 此次出手偷到的铜币数量,如果=-1则表示玩家铜币不足,战斗结束*/
	private int copper;
	/** 如要继续战斗,玩家身上铜币不能低于该值*/
	private int copperLimit;
	public VideoActionStealTargetState() {
	}

	public VideoActionStealTargetState(BattleSoldier target, int skillId, int copper, int copperLimit) {
		super(target);
		this.skillId = skillId;
		this.copper = copper;
		this.copperLimit = copperLimit;
	}

	public int getSkillId() {
		return skillId;
	}

	public void setSkillId(int skillId) {
		this.skillId = skillId;
	}

	public int getCopper() {
		return copper;
	}

	public void setCopper(int copper) {
		this.copper = copper;
	}

	public int getCopperLimit() {
		return copperLimit;
	}

	public void setCopperLimit(int copperLimit) {
		this.copperLimit = copperLimit;
	}
}
