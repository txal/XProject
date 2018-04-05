package com.nucleus.logic.core.modules.battle.dto;

import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.charactor.data.GeneralCharactor;

/**
 * 玩家战斗后士兵信息
 * <p>
 * Created by Tony on 15/7/28.
 */
public class PlayerSoldierInfo {

	private long id;

	private long playerId;

	private int hp;

	private int mp;

	private int maxHp;

	private int maxMp;

	private int type;

	private boolean win;
	/** 第几回合参战 */
	private int joinRound;
	/** 最大伤害 */
	private int maxDamage;
	/** 宠物最大伤害 */
	private int maxPetDamage;

	public PlayerSoldierInfo() {
	}

	public PlayerSoldierInfo(BattleSoldier soldier) {
		this.id = soldier.getId();
		this.playerId = soldier.playerId();
		this.hp = soldier.hp();
		this.mp = soldier.mp();
		this.maxHp = soldier.maxHp();
		this.maxMp = soldier.maxMp();
		this.type = soldier.charactorType();
		this.joinRound = soldier.joinRound();
		this.maxDamage = soldier.getMaxDamage();
		this.maxPetDamage = soldier.getMaxPetDamage();
	}

	public boolean isPet() {
		return type == GeneralCharactor.CharactorType.Pet.ordinal();
	}

	public boolean isMainCharactor() {
		return type == GeneralCharactor.CharactorType.MainCharactor.ordinal();
	}

	public int getMaxDamage() {
		return maxDamage;
	}

	public void setMaxDamage(int maxDamage) {
		this.maxDamage = maxDamage;
	}

	public int getMaxPetDamage() {
		return maxPetDamage;
	}

	public void setMaxPetDamage(int maxPetDamage) {
		this.maxPetDamage = maxPetDamage;
	}

	public boolean isDead() {
		return hp < 1;
	}

	public long getId() {
		return id;
	}

	public void setId(long id) {
		this.id = id;
	}

	public long getPlayerId() {
		return playerId;
	}

	public void setPlayerId(long playerId) {
		this.playerId = playerId;
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

	public int getMaxHp() {
		return maxHp;
	}

	public void setMaxHp(int maxHp) {
		this.maxHp = maxHp;
	}

	public int getMaxMp() {
		return maxMp;
	}

	public void setMaxMp(int maxMp) {
		this.maxMp = maxMp;
	}

	public int getType() {
		return type;
	}

	public void setType(int type) {
		this.type = type;
	}

	public boolean isWin() {
		return win;
	}

	public void setWin(boolean win) {
		this.win = win;
	}

	public int getJoinRound() {
		return joinRound;
	}

	public void setJoinRound(int joinRound) {
		this.joinRound = joinRound;
	}
}
