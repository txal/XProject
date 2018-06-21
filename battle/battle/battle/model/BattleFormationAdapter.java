package com.nucleus.logic.core.modules.battle.model;

import com.nucleus.logic.core.modules.formation.data.Formation;

/**
 * 阵型控制器
 * 
 * @author liguo
 * 
 */
public class BattleFormationAdapter {
	/** 士兵在阵型中信息 */
	private long[] soldierIdsFormation;
	/** 当前阵型 */
	private Formation formation;
	/** 加入计算 */
	private int involveCount = 1;
	/** 最大玩家数 */
	private int maxPlayerSize;

	public BattleFormationAdapter(Battle battle, int formationId) {
		this.formation = Formation.get(formationId);
		this.maxPlayerSize = battle.maxTeamPlayerSize();
		soldierIdsFormation = new long[battle.maxPositionSize()];
	}

	/**
	 * 加入玩家
	 * 
	 * @param mainCharactorSoldier
	 * @param petCharactorSoldier
	 */
	public void involvePlayer(BattleSoldier mainCharactorSoldier, BattleSoldier petCharactorSoldier) {
		involveSoldier(mainCharactorSoldier);
		involvePet(petCharactorSoldier);
		mainCharactorSoldier.setFormationIndex(this.involveCount);
		if (petCharactorSoldier != null) {
			petCharactorSoldier.setFormationIndex(Formation.PET_FORMATION_EFFECT_ID);
		}
		this.involveCount++;
	}

	/**
	 * 加入怪物
	 * 
	 * @param monster
	 */
	public void involveMonster(BattleSoldier monster) {
		involveSoldier(monster);
		monster.setFormationIndex(this.involveCount);
		if (this.involveCount > 5) {
			monster.setFormationIndex(Formation.PET_FORMATION_EFFECT_ID);
		}
		this.involveCount++;
	}

	/**
	 * 加入伙伴
	 * 
	 * @param crewSoldier
	 */
	public void involveCrew(BattleSoldier crewSoldier) {
		involveSoldier(crewSoldier);
		crewSoldier.setFormationIndex(this.involveCount);
		this.involveCount++;
	}

	/**
	 * 加入召唤的小怪
	 * 
	 * @param soldier
	 * @param index
	 *            指定位置索引
	 */
	public void addCalledMonster(BattleSoldier soldier, int index) {
		if (index < 0)
			return;
		soldier.setPosition(index + 1);
		soldierIdsFormation[index] = soldier.getId();
	}

	/**
	 * 查找阵型上空余位置
	 * 
	 * @param ignorePetPos
	 *            是否忽略宠物占位
	 * @return
	 */
	public int findEmptyIndex(boolean ignorePetPos) {
		int index = -1;
		for (int i = 0; i < this.soldierIdsFormation.length; i++) {
			if (this.soldierIdsFormation[i] > 0)
				continue;
			if (!ignorePetPos && i >= 5 && i <= 9)
				continue; // 宠物固定占位
			index = i;
			break;
		}
		return index;
	}

	private void involveSoldier(BattleSoldier soldier) {
		int formationPos = 0;
		if (soldier.battleTeam().leaderId() > 0) {
			formationPos = formation.playerPosition(involveCount);
		} else {
			formationPos = formation.monsterPosition(involveCount);
		}
		soldier.setPosition(formationPos);
		soldierIdsFormation[formationPos - 1] = soldier.getId();
	}

	private void involvePet(BattleSoldier pet) {
		if (null == pet)
			return;
		int position = involveCount + maxPlayerSize;
		pet.setPosition(position);
		soldierIdsFormation[position - 1] = pet.getId();
	}

	public long[] getSoldierIdsFormation() {
		return soldierIdsFormation;
	}

	public void setSoldierIdsFormation(long[] soldierIdsFormation) {
		this.soldierIdsFormation = soldierIdsFormation;
	}

	public int getMaxPlayerSize() {
		return maxPlayerSize;
	}

	public void setMaxPlayerSize(int maxPlayerSize) {
		this.maxPlayerSize = maxPlayerSize;
	}
}
