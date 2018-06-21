package com.nucleus.logic.core.modules.battle.dto;

import java.util.ArrayList;
import java.util.List;

import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;

/**
 * 攻击调试信息
 * 
 * @author wgy
 *
 */
public class AttackDebugInfo {
	/**
	 * 技能触发者信息
	 */
	private String triggerInfo;
	/**
	 * 技能
	 */
	private Skill skill;
	/**
	 * 技能目标信息
	 */
	private String targetInfo;
	/**
	 * 是否命中
	 */
	private boolean hit;
	/**
	 * 命中率
	 */
	private float hitRate;
	/**
	 * 是否暴击
	 */
	private boolean crit;
	/**
	 * 暴击率
	 */
	private float critRate;
	/**
	 * 暴击伤害率
	 */
	private float critHurtRate;
	/**
	 * 目标是否死亡
	 */
	private boolean isTargetDead;
	/**
	 * 目标血量变化(+加血-扣血)
	 */
	private int hp;
	/**
	 * mp变化
	 */
	private int mp;
	/**
	 * sp变化
	 */
	private int sp;
	/**
	 * 目标伤害率
	 */
	private float hurtRate;
	/**
	 * 目标中buff列表
	 */
	private List<BattleBuffEntity> targetBuffs = new ArrayList<BattleBuffEntity>();
	/**
	 * 触发者自身buff列表
	 */
	private List<BattleBuffEntity> triggerBuffs = new ArrayList<BattleBuffEntity>();

	public AttackDebugInfo() {
	}

	public AttackDebugInfo(BattleSoldier trigger, Skill skill, BattleSoldier target) {
		this.triggerInfo = trigger.toBattleInfo();
		this.skill = skill;
		this.targetInfo = target != null ? target.toBattleInfo() : null;
	}

	public void addTargetBuff(BattleBuffEntity buff) {
		this.targetBuffs.add(buff);
	}

	public void addTriggerBuff(BattleBuffEntity buff) {
		this.triggerBuffs.add(buff);
	}

	public Skill getSkill() {
		return skill;
	}

	public void setSkill(Skill skill) {
		this.skill = skill;
	}

	public boolean isHit() {
		return hit;
	}

	public void setHit(boolean hit) {
		this.hit = hit;
	}

	public float getHitRate() {
		return hitRate;
	}

	public void setHitRate(float hitRate) {
		this.hitRate = hitRate;
	}

	public boolean isTargetDead() {
		return isTargetDead;
	}

	public void setTargetDead(boolean isTargetDead) {
		this.isTargetDead = isTargetDead;
	}

	public int getHp() {
		return hp;
	}

	public void setHp(int hp) {
		this.hp = hp;
	}

	public float getHurtRate() {
		return hurtRate;
	}

	public void setHurtRate(float hurtRate) {
		this.hurtRate = hurtRate;
	}

	public int getMp() {
		return mp;
	}

	public void setMp(int mp) {
		this.mp = mp;
	}

	public boolean isCrit() {
		return crit;
	}

	public void setCrit(boolean crit) {
		this.crit = crit;
	}

	public float getCritRate() {
		return critRate;
	}

	public void setCritRate(float critRate) {
		this.critRate = critRate;
	}

	public float getCritHurtRate() {
		return critHurtRate;
	}

	public void setCritHurtRate(float critHurtRate) {
		this.critHurtRate = critHurtRate;
	}

	public List<BattleBuffEntity> getTargetBuffs() {
		return targetBuffs;
	}

	public void setTargetBuffs(List<BattleBuffEntity> targetBuffs) {
		this.targetBuffs = targetBuffs;
	}

	public List<BattleBuffEntity> getTriggerBuffs() {
		return triggerBuffs;
	}

	public void setTriggerBuffs(List<BattleBuffEntity> triggerBuffs) {
		this.triggerBuffs = triggerBuffs;
	}

	public int getSp() {
		return sp;
	}

	public void setSp(int sp) {
		this.sp = sp;
	}

	@Override
	public String toString() {
		StringBuilder sb = new StringBuilder();
		sb.append("trigger:").append(this.triggerInfo);
		sb.append(", skill:").append(this.skill.getName());
		sb.append(", target:").append(this.targetInfo);
		sb.append(", hit:").append(this.hit);
		sb.append(", hitRate:").append(this.hitRate);
		sb.append(", crit:").append(this.crit);
		sb.append(", critRate:").append(this.critRate);
		sb.append(", critHurtRate:").append(this.critHurtRate);
		sb.append(", hp:").append(this.hp);
		sb.append(", mp:").append(this.mp);
		sb.append(", sp:").append(this.sp);
		sb.append(", hurtRate:").append(this.hurtRate);
		sb.append(", targetDead:").append(this.isTargetDead);
		sb.append(", triggerBuffs:[");
		for (BattleBuffEntity buff : this.triggerBuffs)
			sb.append("{buffId:").append(buff.battleBuffId()).append(", buffName:").append(buff.battleBuff().getName()).append(", persistRounds:").append(buff.getBuffPersistRound()).append("}, ");
		sb.append("]");
		sb.append(", targetBuffs:[");
		for (BattleBuffEntity buff : this.targetBuffs)
			sb.append("{buffId:").append(buff.battleBuffId()).append(", buffName:").append(buff.battleBuff().getName()).append(", persistRounds:").append(buff.getBuffPersistRound()).append("}, ");
		sb.append("]");
		return sb.toString();
	}
}
