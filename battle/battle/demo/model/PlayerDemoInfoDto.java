package com.nucleus.logic.core.modules.demo.model;

import com.nucleus.commons.message.GeneralResponse;
import com.nucleus.logic.core.modules.charactor.dto.CharactorDto;
import com.nucleus.logic.core.modules.demo.dto.DemoMonsterConfigDto;
import com.nucleus.logic.core.modules.scene.model.ScenePlayer;

public class PlayerDemoInfoDto extends GeneralResponse {

	/** 玩家编号 */
	private long playerId;

	/** 玩家角色 */
	private CharactorDto playerCharactor;

	private DemoMonsterConfigDto monsterInfo;

	public PlayerDemoInfoDto() {
	}

	public PlayerDemoInfoDto(ScenePlayer player, CharactorDto playerCharactor, DemoMonsterConfigDto monsterInfo) {
		this.setPlayerId(player.getId());
		this.setPlayerCharactor(playerCharactor);
		this.monsterInfo = monsterInfo;
	}

	public long getPlayerId() {
		return playerId;
	}

	public void setPlayerId(long playerId) {
		this.playerId = playerId;
	}

	public CharactorDto getPlayerCharactor() {
		return playerCharactor;
	}

	public void setPlayerCharactor(CharactorDto playerCharactor) {
		this.playerCharactor = playerCharactor;
	}

	public DemoMonsterConfigDto getMonsterInfo() {
		return monsterInfo;
	}

	public void setMonsterInfo(DemoMonsterConfigDto monsterInfo) {
		this.monsterInfo = monsterInfo;
	}
}
