/**
 * 
 */
package com.nucleus.logic.core.modules.battle;

import java.util.Set;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;

import com.google.common.collect.ImmutableSet;
import com.nucleus.AppServerMode;
import com.nucleus.commons.annotation.RequestType;
import com.nucleus.commons.exception.GeneralException;
import com.nucleus.commons.message.MultiGeneralController;
import com.nucleus.logic.core.modules.AppErrorCodes;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.dto.BattleWatchDto;
import com.nucleus.logic.core.modules.battle.dto.BattleWatchExit;
import com.nucleus.logic.core.modules.battle.dto.Video;
import com.nucleus.logic.core.modules.battle.manager.BattleManager;
import com.nucleus.logic.core.modules.battle.model.Battle;
import com.nucleus.logic.core.modules.charactor.model.PersistPlayerChild;
import com.nucleus.logic.core.modules.charactor.model.PersistPlayerPet;
import com.nucleus.logic.core.modules.player.data.FunctionOpen;
import com.nucleus.logic.core.modules.player.data.FunctionOpen.FunctionOpenEnum;
import com.nucleus.logic.core.modules.player.model.PersistPlayer;
import com.nucleus.logic.core.modules.scene.manager.SceneManager;
import com.nucleus.logic.core.modules.scene.manager.ScenePlayerManager;
import com.nucleus.logic.core.modules.scene.model.NpcSceneMonsterInfo;
import com.nucleus.logic.core.modules.scene.model.Scene;
import com.nucleus.logic.core.modules.scene.model.ScenePlayer;
import com.nucleus.logic.core.vo.DefaultBattleSkillVo;

/**
 * 指令
 * 
 * @author Omanhom
 * 
 */
@Controller
public class CommandController extends MultiGeneralController {

	@Autowired
	private ScenePlayerManager playerManager;

	@Autowired
	private CommandService commandService;

	@Autowired
	private BattleManager battleManager;

	@Autowired
	private SceneManager sceneManager;

	/**
	 * 技能目标
	 * 
	 * @param battleId
	 * @param round
	 * @param ifMainCharactor
	 * @param skillId
	 * @param targetId
	 */
	@RequestType(5)
	public void skillTarget(long battleId, int round, boolean ifMainCharactor, int skillId, long targetId) {
		ScenePlayer player = playerManager.getRequestPlayer();
		commandService.skillTarget(player, battleId, round, ifMainCharactor, skillId, targetId, -1);
		player.successResponse();
	}

	/**
	 * 自动战斗
	 * 
	 * @param battleId
	 */
	@RequestType(5)
	public void autoBattle(long battleId) {
		ScenePlayer player = playerManager.getRequestPlayer();
		commandService.assignAutoBattle(player, battleId, true);
		player.successResponse();
	}

	/**
	 * 取消自动战斗
	 * 
	 * @param battleId
	 */
	@RequestType(5)
	public void cancelAutoBattle(long battleId) {
		ScenePlayer player = playerManager.getRequestPlayer();
		commandService.assignAutoBattle(player, battleId, false);
		player.successResponse();
	}

	/**
	 * 设置主人物，宠物默认战斗技能
	 * 
	 * @param mainCharactorDefaultBattleSkillId
	 * @param petDefaultBattleSkillId
	 */
	@RequestType(5)
	public void populateDefaultBattleSkillId(int mainCharactorDefaultBattleSkillId, int petDefaultBattleSkillId) {
		populateDefaultSkillId(mainCharactorDefaultBattleSkillId, petDefaultBattleSkillId, true);
	}

	/**
	 * 设置主角、宠物、子女默认技能
	 * 
	 * @param mainCharactorSkillId
	 * @param petOrChildSkillId
	 * @param isPet
	 */
	@RequestType(5)
	public void populateDefaultSkillId(int mainCharactorSkillId, int petOrChildSkillId, boolean isPet) {
		ScenePlayer player = playerManager.getRequestPlayer();
		if (mainCharactorSkillId > 0) {
			if (Skill.get(mainCharactorSkillId) == null)
				throw new GeneralException(AppErrorCodes.BATTLE_SKILL_NOT_EXIST);
			PersistPlayer persistPlayer = player.persistPlayer();
			persistPlayer.setDefaultSkillId(mainCharactorSkillId);
		}
		if (petOrChildSkillId > 0) {
			if (Skill.get(petOrChildSkillId) == null)
				throw new GeneralException(AppErrorCodes.BATTLE_SKILL_NOT_EXIST);
			if (isPet) {
				PersistPlayerPet persistPlayerPet = player.battlePet();
				if (persistPlayerPet != null)
					persistPlayerPet.setDefaultSkillId(petOrChildSkillId);
			} else {
				PersistPlayerChild ppc = player.battleChild();
				if (ppc != null)
					ppc.setDefaultSkillId(petOrChildSkillId);
			}
		}
		Battle battle = battleManager.battleByPlayer(player.getId());
		if (battle != null)
			battle.populateDefaultSkill(player, mainCharactorSkillId, petOrChildSkillId);
		sceneManager.forward(AppServerMode.Core, new DefaultBattleSkillVo(player.getId(), mainCharactorSkillId, petOrChildSkillId, isPet));
	}

	/**
	 * 观看NPC战斗，统一下发BattleWatchDto
	 *
	 * @param npcUniqueId
	 *            被观看者玩家ID
	 */
	@RequestType(5)
	public void watchBattleNPC(long npcUniqueId) {
		ScenePlayer watchPlayer = playerManager.getRequestPlayer();
		if (watchPlayer.ifInBattle()) {
			throw new GeneralException(AppErrorCodes.BATTLE_WATCH_IN_BATTLE);
		}
		Scene scene = sceneManager.createIfAbsent(watchPlayer.getSceneId());
		NpcSceneMonsterInfo npcSceneMonsterInfo = scene.get(npcUniqueId);
		if (npcSceneMonsterInfo == null)
			throw new GeneralException(AppErrorCodes.NPC_MONSTER_DISAPPEAR);
		if (!npcSceneMonsterInfo.ifInBattle())
			throw new GeneralException(AppErrorCodes.BATTLE_ID_NOT_FOUND);
		long battleId = npcSceneMonsterInfo.getBattleId();
		Battle battle = battleManager.get(battleId);
		if (battle == null)
			throw new GeneralException(AppErrorCodes.BATTLE_ID_NOT_FOUND);
		Long realPlayerId = battle.battleInfo().getAteam().leaderId();
		Set<Long> watchPlayerIds = ImmutableSet.of(watchPlayer.getId());
		if (watchPlayer.ifTeamLeader()) {
			watchPlayerIds = watchPlayer.teamPlayerIds(true);
		}
		battleManager.watch(realPlayerId, watchPlayerIds, true);
	}

	/**
	 * 观看某场战斗，统一下发BattleWatchDto
	 * 
	 * @param playerId
	 *            被观看者玩家ID
	 */
	@RequestType(5)
	public void watchBattle(long playerId) {
		ScenePlayer watchPlayer = playerManager.getRequestPlayer();
		if (watchPlayer.ifInBattle()) {
			throw new GeneralException(AppErrorCodes.BATTLE_WATCH_IN_BATTLE);
		}
		Battle battle = battleManager.battleByPlayer(playerId);
		if (battle == null)
			throw new GeneralException(AppErrorCodes.BATTLE_ID_NOT_FOUND);
		Long realPlayerId = battleManager.getBeWatchPlayerId(playerId);
		if (realPlayerId == null) {
			realPlayerId = playerId;
		}
		Set<Long> watchPlayerIds = ImmutableSet.of(watchPlayer.getId());
		if (watchPlayer.ifTeamLeader()) {
			watchPlayerIds = watchPlayer.teamPlayerIds(true);
		}
		BattleWatchDto dto = battleManager.watch(realPlayerId, watchPlayerIds, true);
		if (dto == null)
			throw new GeneralException(AppErrorCodes.BATTLE_ID_NOT_FOUND);
		watchPlayer.successResponse();
	}

	/**
	 * 观看某场战斗，统一下发BattleWatchDto
	 * 
	 * @param playerId
	 *            被观看者玩家ID
	 * @param battleId
	 *            战斗ID
	 */
	@RequestType(5)
	public void watchBattleByBattleId(long playerId, long battleId) {
		ScenePlayer watchPlayer = playerManager.getRequestPlayer();
		if (watchPlayer.ifInBattle())
			throw new GeneralException(AppErrorCodes.BATTLE_WATCH_IN_BATTLE);
		Long realPlayerId = battleManager.getBeWatchPlayerId(playerId);
		if (realPlayerId == null)
			realPlayerId = playerId;
		Set<Long> watchPlayerIds = ImmutableSet.of(watchPlayer.getId());
		if (watchPlayer.ifTeamLeader()) {
			watchPlayerIds = watchPlayer.teamPlayerIds(true);
		}
		BattleWatchDto dto = battleManager.watch(realPlayerId, battleId, watchPlayerIds, true);
		if (dto == null)
			throw new GeneralException(AppErrorCodes.BATTLE_ID_NOT_FOUND);
		watchPlayer.successResponse();
	}

	/**
	 * 退出观战, 统一下发BattleWatchExit
	 * 
	 * @param battleId
	 */
	@RequestType(5)
	public void exitWatchBattle(long battleId) {
		ScenePlayer watchPlayer = playerManager.getRequestPlayer();
		Set<Long> watchPlayerIds = ImmutableSet.of(watchPlayer.getId());
		if (watchPlayer.ifTeamLeader()) {
			watchPlayerIds = watchPlayer.teamPlayerIds(true);
		}
		boolean success = battleManager.watchExit(battleId, watchPlayerIds, true);
		if (!success) {
			// 如果战斗不存在,例如队长强退战斗, 战斗已经删除, 也发一个退出通知让客户端可以关闭观战
			watchPlayer.deliver(new BattleWatchExit(battleId));
		}
	}

	/**
	 * 换宠
	 * 
	 * @param battleId
	 * @param petUniqueId
	 * @param round
	 */
	@RequestType(5)
	public void changePet(long battleId, long petUniqueId, int round) {
		if (petUniqueId <= 0)
			return;
		ScenePlayer player = playerManager.getRequestPlayer();
		commandService.changePet(player, battleId, petUniqueId, round);
	}

	/**
	 * 换子女上阵
	 * 
	 * @param battleId
	 * @param childUniqueId
	 * @param round
	 */
	@RequestType(5)
	public void changeChild(long battleId, long childUniqueId, int round) {
		if (childUniqueId <= 0)
			return;
		ScenePlayer player = playerManager.getRequestPlayer();
		commandService.changeChild(player, battleId, childUniqueId, round);
	}

	/**
	 * 使用物品
	 * 
	 * @param battleId
	 *            战斗唯一编号
	 * @param round
	 *            当前回合,用于校验
	 * @param ifMainCharactor
	 *            是否主角
	 * @param targetId
	 *            目标id
	 * @param itemIndex
	 *            使用物品的背包格子索引
	 */
	@RequestType(5)
	public void useItem(long battleId, int round, boolean ifMainCharactor, long targetId, int itemIndex) {
		if (itemIndex < 0)
			return;
		ScenePlayer player = playerManager.getRequestPlayer();
		/** 战斗系统：物品功能 功能表 */
		FunctionOpen.checkFunctionOpen(player, FunctionOpenEnum.BattleItems);

		commandService.skillTarget(player, battleId, round, ifMainCharactor, CommandService.USE_ITEM_SKILL_ID, targetId, itemIndex);
		player.successResponse();
	}

	/**
	 * 返回玩家当前战斗(无则null)
	 *
	 * @param battleId
	 * @return
	 */
	@RequestType(5)
	public Video getVideo(long battleId) {
		ScenePlayer player = playerManager.getRequestPlayer();
		Video video = null;
		if (battleId <= 0) {
			video = BattleManager.getInstance().existingBattle(player.getId());
		} else {
			Battle battle = battleManager.get(battleId);
			if (battle != null) {
				video = battle.getVideo();
			}
		}
		if (video == null) {
			throw new GeneralException(AppErrorCodes.BATTLE_ID_NOT_FOUND);
		}
		return video;
	}

	/**
	 * 下命令
	 * 
	 * @param command
	 */
	@RequestType(5)
	public void order(long battleId, long targetId, String command) {
		ScenePlayer player = playerManager.getRequestPlayer();
		commandService.order(player, battleId, targetId, command, false);
	}

	/**
	 * 清理指令
	 * 
	 * @param battleId
	 */
	@RequestType(5)
	public void clearOrder(long battleId) {
		ScenePlayer player = playerManager.getRequestPlayer();
		commandService.order(player, battleId, 0, null, true);
	}

	/**
	 * 客户端回合准备就绪
	 * 
	 * @param battleId
	 */
	@RequestType(5)
	public void roundReady(long battleId) {
		ScenePlayer player = playerManager.getRequestPlayer();
		commandService.roundReady(player, battleId);
	}
}
