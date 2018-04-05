package com.nucleus.logic.core.modules.battle.dto;

import com.nucleus.logic.core.modules.scene.data.NpcSceneMonster;
import com.nucleus.logic.core.modules.scene.dto.NpcMonsterVideo;
import com.nucleus.logic.core.modules.scene.model.NpcSceneWorldBossBattle;
import com.nucleus.logic.core.modules.scene.model.NpcSceneMonsterInfo.NpcSceneMonsterBronType;

/**
 * 世界boss战斗
 * 
 * @author wgy
 *
 */
public class WorldBossBattleVideo extends NpcMonsterVideo {

	public WorldBossBattleVideo(int maxRound, NpcSceneWorldBossBattle battle, NpcSceneMonster npcSceneMonster, NpcSceneMonsterBronType type) {
		super(maxRound, battle, npcSceneMonster, type);
	}

}
