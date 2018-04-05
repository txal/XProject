package com.nucleus.logic.core.modules.battle.dto;

import java.util.Set;

import com.nucleus.commons.message.GeneralResponse;
import com.nucleus.logic.core.modules.battle.model.BattlePlayerSoldierInfo;

/**
 * 参战玩家信息
 * 
 * @author wgy
 *
 */
public class BattlePlayerInfoDto extends GeneralResponse {
	private long playerId;
	/**
	 * 已使用物品数量
	 */
	private int useItemCount;
	/**
	 * 所有已召唤宠物id
	 */
	private Set<Long> allPetSoldierIds;

	public BattlePlayerInfoDto() {
	}

	public BattlePlayerInfoDto(BattlePlayerSoldierInfo info) {
		this.playerId = info.mainCharactorSoldierId();
		this.allPetSoldierIds = info.getAllPetSoldierIds();
		this.useItemCount = info.getUseItemCount();
	}

	public int getUseItemCount() {
		return useItemCount;
	}

	public void setUseItemCount(int useItemCount) {
		this.useItemCount = useItemCount;
	}

	public Set<Long> getAllPetSoldierIds() {
		return allPetSoldierIds;
	}

	public void setAllPetSoldierIds(Set<Long> allPetSoldierIds) {
		this.allPetSoldierIds = allPetSoldierIds;
	}

	public long getPlayerId() {
		return playerId;
	}

	public void setPlayerId(long playerId) {
		this.playerId = playerId;
	}
}
