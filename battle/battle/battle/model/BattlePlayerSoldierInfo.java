package com.nucleus.logic.core.modules.battle.model;

import java.util.Collections;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

public class BattlePlayerSoldierInfo {

	/** 主人物士兵 */
	private long mainCharactorSoldierId;

	/** 宠物士兵 */
	private long petSoldierId;
	/** 本场战斗已经出场的宠物id */
	private Set<Long> allPetSoldierIds;
	/** 已使用物品数量 */
	private int useItemCount;

	public BattlePlayerSoldierInfo() {
	}

	public BattlePlayerSoldierInfo(long mainCharactorSoldierId, long petSoldierId) {
		this.mainCharactorSoldierId = mainCharactorSoldierId;
		this.petSoldierId = petSoldierId;
		this.allPetSoldierIds = Collections.newSetFromMap(new ConcurrentHashMap<Long, Boolean>());
		addPetSoldierId(petSoldierId);
	}

	public void addUseItemCount(int count) {
		this.useItemCount += count;
	}

	public void addPetSoldierId(long petSoldierId) {
		if (petSoldierId > 0)
			this.allPetSoldierIds.add(petSoldierId);
	}

	public long battleSoldierByInd(boolean ifMainCharactor) {
		return ifMainCharactor ? mainCharactorSoldierId() : petSoldierId();
	}

	public long mainCharactorSoldierId() {
		return mainCharactorSoldierId;
	}

	public long petSoldierId() {
		return petSoldierId;
	}

	public void setPetSoldierId(long petSoldierId) {
		this.petSoldierId = petSoldierId;
		this.addPetSoldierId(petSoldierId);
	}

	public Set<Long> getAllPetSoldierIds() {
		return this.allPetSoldierIds;
	}

	public int getUseItemCount() {
		return useItemCount;
	}

	public void setUseItemCount(int useItemCount) {
		this.useItemCount = useItemCount;
	}
}
