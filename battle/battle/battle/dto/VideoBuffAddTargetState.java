/**
 * 
 */
package com.nucleus.logic.core.modules.battle.dto;

import com.nucleus.commons.data.DataId;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;

/**
 * buff状态
 * 
 * @author liguo
 * 
 */
public class VideoBuffAddTargetState extends VideoTargetState {
	public VideoBuffAddTargetState(BattleBuffEntity buffEntity) {
		super(buffEntity.getEffectSoldier());
		this.round = buffEntity.getBuffPersistRound();
		this.battleBuffId = buffEntity.battleBuff().getId();
		this.effectValue = buffEntity.getBuffEffectValue();
		this.skillId = buffEntity.skillId();
	}

	public VideoBuffAddTargetState() {
	}

	/** 剩余回合数 */
	private int round;

	/** buffer编号 */
	@DataId(BattleBuff.class)
	private int battleBuffId;
	/** 效果值 */
	private int effectValue;
	/** 技能ID */
	private int skillId;

	public int getRound() {
		return round;
	}

	public void setRound(int round) {
		this.round = round;
	}

	public int getBattleBuffId() {
		return battleBuffId;
	}

	public void setBattleBuffId(int battleBuffId) {
		this.battleBuffId = battleBuffId;
	}

	public int getEffectValue() {
		return effectValue;
	}

	public void setEffectValue(int effectValue) {
		this.effectValue = effectValue;
	}

	public int getSkillId() {
		return skillId;
	}

	public void setSkillId(int skillId) {
		this.skillId = skillId;
	}

}
