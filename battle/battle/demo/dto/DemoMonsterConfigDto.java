package com.nucleus.logic.core.modules.demo.dto;

import java.beans.Transient;

import org.apache.commons.lang3.builder.ReflectionToStringBuilder;
import org.apache.commons.lang3.builder.ToStringStyle;

import com.nucleus.commons.data.DataId;
import com.nucleus.commons.message.GeneralResponse;
import com.nucleus.logic.core.modules.battle.data.Monster;

/**
 * demo战斗中怪物设置
 * 
 * @author wgy
 *
 */
public class DemoMonsterConfigDto extends GeneralResponse {
	/**
	 * 怪物id
	 */
	@DataId(value = Monster.class)
	private int monsterId;
	/**
	 * 速度
	 */
	private String speed;
	/**
	 * 攻击力
	 */
	private String attack;
	/**
	 * 防御力
	 */
	private String defense;
	/**
	 * hp
	 */
	private String hp;
	/**
	 * 灵力
	 */
	private String magic;
	/**
	 * 主动技能
	 */
	private String activeSkillIds;
	/**
	 * 被动技能
	 */
	private String passiveSkillIds;

	private transient Monster monster;

	public int getMonsterId() {
		return monsterId;
	}

	public void setMonsterId(int monsterId) {
		this.monsterId = monsterId;
	}

	public String getSpeed() {
		return speed;
	}

	public void setSpeed(String speed) {
		this.speed = speed;
	}

	public String getAttack() {
		return attack;
	}

	public void setAttack(String attack) {
		this.attack = attack;
	}

	public String getDefense() {
		return defense;
	}

	public void setDefense(String defense) {
		this.defense = defense;
	}

	public String getHp() {
		return hp;
	}

	public void setHp(String hp) {
		this.hp = hp;
	}

	public String getActiveSkillIds() {
		return activeSkillIds;
	}

	public void setActiveSkillIds(String activeSkillIds) {
		this.activeSkillIds = activeSkillIds;
	}

	public String getPassiveSkillIds() {
		return passiveSkillIds;
	}

	public void setPassiveSkillIds(String passiveSkillIds) {
		this.passiveSkillIds = passiveSkillIds;
	}

	public String getMagic() {
		return magic;
	}

	public void setMagic(String magic) {
		this.magic = magic;
	}

	public Monster getMonster() {
		return monster;
	}

	@Transient
	public void setMonster(Monster monster) {
		this.monster = monster;
	}

	@Override
	public String toString() {
		return ReflectionToStringBuilder.toString(this, ToStringStyle.SHORT_PREFIX_STYLE);
	}
}
