/**
 * 
 */
package com.nucleus.logic.core.modules.battle.dto;

import org.apache.commons.lang3.builder.ReflectionToStringBuilder;
import org.apache.commons.lang3.builder.ToStringStyle;

import com.nucleus.logic.core.modules.battle.model.BattleSoldier;

/**
 * @author Omanhom
 * 
 */
public class VideoActionTargetState extends VideoTargetState {
	public VideoActionTargetState() {
	}

	public VideoActionTargetState(BattleSoldier target, int hp, int mp, boolean crit) {
		super(target);
		this.hp = hp;
		this.mp = mp;
		this.crit = crit;
		this.currentHp = target.hp();
		this.currentSp = target.getSp();
		this.soldierStatus = target.soldierStatus().ordinal();
		// if (hp > 0 && hp == this.currentHp && target.deadSp() > 0) {// 死后，变化值等于当前值，表示复活，保留原来的怒气值
		// this.sp = target.getSp();
		// target.clearDeadSp();
		// }
	}

	public VideoActionTargetState(BattleSoldier target, int hp, int mp, boolean crit, int sp) {
		this(target, hp, mp, crit);
		if (sp != 0) {
			this.sp = sp;
		}
		this.soldierStatus = target.soldierStatus().ordinal();
	}

	public VideoActionTargetState(BattleSoldier target, int hp, int mp, boolean crit, int sp, int magicMana) {
		this(target, hp, mp, crit, sp);
		this.magicMana = magicMana;
	}

	public VideoActionTargetState(BattleSoldier target, int hp, int mp, boolean crit, int sp, int magicMana, int maxHp) {
		this(target, hp, mp, crit, sp, magicMana);
		this.maxHp = target.maxHp();
	}

	/** 是否暴击 */
	private boolean crit;
	/** 有正负之分 */
	private int hp;
	private int mp;
	/** 怒气 */
	private int sp;
	/** 目标当前血量 */
	private int currentHp;
	/** 目标防御状态 */
	private int soldierStatus;
	/** 法宝法力 */
	private int magicMana;
	/** 当前怒气 */
	private int currentSp;
	/** 血量最大值 */
	private int maxHp;

	public boolean isCrit() {
		return crit;
	}

	public void setCrit(boolean crit) {
		this.crit = crit;
	}

	public int getHp() {
		return hp;
	}

	public void setHp(int hp) {
		this.hp = hp;
	}

	public int getMp() {
		return mp;
	}

	public void setMp(int mp) {
		this.mp = mp;
	}

	public int getSp() {
		return sp;
	}

	public void setSp(int sp) {
		this.sp = sp;
	}

	public int getCurrentHp() {
		return currentHp;
	}

	public void setCurrentHp(int currentHp) {
		this.currentHp = currentHp;
	}

	@Override
	public String toString() {
		return ReflectionToStringBuilder.toString(this, ToStringStyle.SHORT_PREFIX_STYLE);
	}

	public int getSoldierStatus() {
		return soldierStatus;
	}

	public void setSoldierStatus(int soldierStatus) {
		this.soldierStatus = soldierStatus;
	}

	public int getMagicMana() {
		return magicMana;
	}

	public void setMagicMana(int magicMana) {
		this.magicMana = magicMana;
	}

	public int getCurrentSp() {
		return currentSp;
	}

	public void setCurrentSp(int currentSp) {
		this.currentSp = currentSp;
	}

	public int getMaxHp() {
		return maxHp;
	}

	public void setMaxHp(int maxHp) {
		this.maxHp = maxHp;
	}
}
