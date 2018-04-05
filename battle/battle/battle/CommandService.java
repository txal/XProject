/**
 * 
 */
package com.nucleus.logic.core.modules.battle;

import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Set;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.nucleus.AppServerMode;
import com.nucleus.commons.data.StaticConfig;
import com.nucleus.commons.exception.GeneralException;
import com.nucleus.logic.core.modules.AppErrorCodes;
import com.nucleus.logic.core.modules.AppStaticConfigs;
import com.nucleus.logic.core.modules.athletics.model.CSAthleticsBattle;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.data.Skill.UserTargetScopeType;
import com.nucleus.logic.core.modules.battle.dto.BattleSoldierReadyNotify;
import com.nucleus.logic.core.modules.battle.dto.CommandNotify;
import com.nucleus.logic.core.modules.battle.manager.BattleManager;
import com.nucleus.logic.core.modules.battle.model.ArenaBattle;
import com.nucleus.logic.core.modules.battle.model.Battle;
import com.nucleus.logic.core.modules.battle.model.BattleInfo;
import com.nucleus.logic.core.modules.battle.model.BattlePlayerSoldierInfo;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.BattleTeam;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battle.model.PveBattle;
import com.nucleus.logic.core.modules.battle.model.PvpBattle;
import com.nucleus.logic.core.modules.charactor.data.Child;
import com.nucleus.logic.core.modules.charactor.data.GeneralCharactor.CharactorType;
import com.nucleus.logic.core.modules.charactor.data.Pet;
import com.nucleus.logic.core.modules.charactor.model.PersistPlayerChild;
import com.nucleus.logic.core.modules.charactor.model.PersistPlayerPet;
import com.nucleus.logic.core.modules.glory.GloryFightBattle;
import com.nucleus.logic.core.modules.player.data.Props;
import com.nucleus.logic.core.modules.player.data.Props.ScopeEnum;
import com.nucleus.logic.core.modules.scene.model.ScenePlayer;
import com.nucleus.logic.core.modules.system.dto.ObjectStatusResponse;
import com.nucleus.logic.scene.SceneModeService;
import com.nucleus.logic.scene.cross.CrossServerUtils;
import com.nucleus.logic.scene.modules.scene.manager.CoreService;
import com.nucleus.outer.msg.GeckoMultiMessage;
import com.nucleus.player.model.PlayerAsyncRequestListener;

/**
 * @author Omanhom
 * 
 */
@Service
public class CommandService {
	/**
	 * 召唤技能id
	 */
	public static final int SUMMON_SKILL_ID = StaticConfig.get(AppStaticConfigs.DEFAULT_SUMMON_SKILL_ID).getAsInt(4);
	/**
	 * 使用物品技能id
	 */
	public static final int USE_ITEM_SKILL_ID = StaticConfig.get(AppStaticConfigs.USE_ITEM_SKILL_ID).getAsInt(7);
	/**
	 * 最多使用物品数量
	 */
	public static final int MAX_USE_ITEM_COUNT = StaticConfig.get(AppStaticConfigs.MAX_USE_ITEM_COUNT).getAsInt(10);
	/**
	 * 竞技战最多使用物品数量
	 */
	public static final int CSATH_MAX_USE_ITEM_COUNT = StaticConfig.get(AppStaticConfigs.ATHLETICS_USE_ITEM_LIMIT).getAsInt(3);

	@Autowired
	private BattleManager battleManager;
	@Autowired
	private SceneModeService sceneModeService;
	@Autowired
	private CoreService coreService;

	/**
	 * 技能目标
	 *
	 * @param player
	 * @param battleId
	 * @param round
	 * @param ifMainCharactor
	 * @param skillId
	 * @param targetId
	 * @param itemIndex
	 */
	public void skillTarget(ScenePlayer player, long battleId, int round, boolean ifMainCharactor, int skillId, long targetId, int itemIndex) {
		Battle battle = checkBattle(player, round, battleId);

		BattleInfo battleInfo = battle.battleInfo();
		BattleTeam myTeam = battleInfo.myTeam(player.getId());

		BattlePlayerSoldierInfo playerSoldiersInfo = myTeam.soldiersByPlayer(player.getId());
		if (null == playerSoldiersInfo)
			throw new GeneralException(AppErrorCodes.BATTLE_SOLDIER_NOT_EXIST);
		BattleSoldier trigger = myTeam.soldier(playerSoldiersInfo.battleSoldierByInd(ifMainCharactor));
		if (!trigger.isDead() && null != trigger.getCommandContext())
			throw new GeneralException(AppErrorCodes.BATTLE_SKILL_COMMAND_EXIST);
		Skill skill = trigger.skillHolder().activeSkill(skillId);
		if (null == skill)
			throw new GeneralException(AppErrorCodes.BATTLE_SKILL_NOT_EXIST);
		if ((skill.getBattleType() == Skill.BattleType.PVE.ordinal() && !(battle instanceof PveBattle)) || (skill.getBattleType() == Skill.BattleType.PVP.ordinal() && !(battle instanceof PvpBattle)))
			throw new GeneralException(AppErrorCodes.SKILL_NOT_ALLOW);
		UserTargetScopeType scopeType = UserTargetScopeType.values()[skill.getSkillAiId()];
		Props props = null;
		if (skill.getId() == USE_ITEM_SKILL_ID) {
			props = checkForItem(player, trigger, itemIndex);
			scopeType = UserTargetScopeType.values()[props.getTargetType()];
		}
		boolean valid = myTeam.validateTarget(scopeType, trigger.getId(), targetId);
		if (!valid) {
			if (scopeType == UserTargetScopeType.Fere)
				throw new GeneralException(AppErrorCodes.SKILL_FOR_FERE_ONLY);
			else
				throw new GeneralException(AppErrorCodes.BATTLE_SKILL_TRAGET_INVALID);
		}
		BattleSoldier target = null;
		long petUniqueId = 0;
		switch (scopeType) {
			case Self:
				target = trigger;
				break;
			case Enemy:
				target = battleInfo.enemyTeam(player.getId()).soldier(targetId);
				break;
			case FriendsExceptSelfWithPet:
			case FriendsWithPet:
			case FriendPets:
				target = myTeam.soldier(targetId);
				break;
			case ExceptSelf:
				target = myTeam.soldier(targetId);
				if (target == null)
					target = battleInfo.enemyTeam(player.getId()).soldier(targetId);
				break;
			case PetsInBag:
				petUniqueId = targetId;
				break;
			case Fere:
				target = myTeam.soldier(trigger.fereId());
				break;
			case EnemyPlayer:
				target = battleInfo.enemyTeam(player.getId()).soldier(targetId);
				break;
			case MyTeamPlayer:
				target = myTeam.soldier(targetId);
				break;
			case EnemyPets:
				target = battleInfo.enemyTeam(player.getId()).soldier(targetId);
				break;
			default:
		}

		if (target != null && props != null) {
			if (props.isReliveTarget() && !target.canUseReliveProp())
				throw new GeneralException(AppErrorCodes.CANNOT_RELIVE_TARGET);
			else if (props.healTarget() && target.preventHeal())
				throw new GeneralException(AppErrorCodes.CANNOT_HEAL_TARGET);
		}
		CommandContext commandContext = new CommandContext(trigger, skill, target, petUniqueId, itemIndex, props);
		trigger.setAutoBattle(false);
		trigger.initCommandContext(commandContext);

		readyNotify(trigger);
	}

	private Props checkForItem(ScenePlayer player, BattleSoldier trigger, int itemIndex) {
		ObjectStatusResponse<Integer> result = coreService.checkForItem(player.getId(), itemIndex);
		if (result.getErrorCode() > 0) {
			throw new GeneralException(result.getErrorCode());
		}
		Props props = Props.get(result.getObject());
		if (props.getTriggerType() == CharactorType.MainCharactor.ordinal() && !trigger.isMainCharactor())
			throw new GeneralException(AppErrorCodes.USER_TYPE_NOT_SUIT);
		BattlePlayerSoldierInfo info = trigger.battleTeam().soldiersByPlayer(trigger.playerId());
		if (info != null && info.getUseItemCount() >= MAX_USE_ITEM_COUNT)
			throw new GeneralException(AppErrorCodes.OUT_OF_USE_ITEM_COUNT, info.getUseItemCount());
		// 竞技战最多使用3次药品
		if (trigger.battle() instanceof CSAthleticsBattle) {
			if (info != null && info.getUseItemCount() >= CSATH_MAX_USE_ITEM_COUNT)
				throw new GeneralException(AppErrorCodes.OUT_OF_USE_ITEM_COUNT, info.getUseItemCount());
		}
		if (props.getScopeId() == ScopeEnum.ArenaBattle.ordinal() && !(trigger.battle() instanceof ArenaBattle))
			throw new GeneralException(AppErrorCodes.USE_BATTLE_TYPE_NOT_SUIT);
		if ((props.getScopeId() == ScopeEnum.Cross.ordinal() || props.getScopeId() == ScopeEnum.CrossBackpack.ordinal()) && !CrossServerUtils.isCrossSceneServer())
			throw new GeneralException(AppErrorCodes.USE_BATTLE_TYPE_NOT_SUIT);
		if (props.getScopeId() == ScopeEnum.Glory.ordinal() && !(trigger.battle() instanceof GloryFightBattle))
			throw new GeneralException(AppErrorCodes.USE_BATTLE_TYPE_NOT_SUIT);
		return props;
	}

	private void readyNotify(BattleSoldier trigger) {
		if (trigger.team().playerIds().size() > 1) {
			Set<Long> playerIds = new HashSet<>(trigger.team().playerIds());
			for (Iterator<Long> it = playerIds.iterator(); it.hasNext();) {
				if (it.next().longValue() == trigger.playerId())
					it.remove();
			}
			if (!playerIds.isEmpty())
				sceneModeService.toOuter().send(new GeckoMultiMessage(new BattleSoldierReadyNotify(trigger.getId()), playerIds));
		}

	}

	/**
	 * 
	 * @param isAuto
	 *            是否自动
	 */
	public void assignAutoBattle(ScenePlayer player, long battleId, boolean isAuto) {
		Battle battle = battleManager.get(battleId);
		if (null == battle)
			throw new GeneralException(AppErrorCodes.BATTLE_ID_NOT_FOUND);
		if (battle.isRoundRunning()) {
			battle.getLog().info("ignore command when round running");
			return;
		}
		if (battle.needPlayerAutoBattle())
			player.setAutoBattle(isAuto);
		BattleTeam playerTeam = battle.battleInfo().myTeam(player.getId());
		BattlePlayerSoldierInfo targetSoldiers = playerTeam.soldiersByPlayer(player.getId());
		autoBattle(playerTeam.battleSoldier(targetSoldiers.mainCharactorSoldierId()), isAuto);
		autoBattle(playerTeam.battleSoldier(targetSoldiers.petSoldierId()), isAuto);
	}

	/**
	 * 换宠
	 * 
	 * @param player
	 * @param battleId
	 * @param petUniqueId
	 *            要被换上阵的宠物唯一编号
	 * @param round
	 */
	public void changePet(ScenePlayer player, long battleId, long petUniqueId, int round) {
		// 异步先取宠物回来, 缓存到换宠技能使用
		final int mode = AppServerMode.Core.ordinal();
		final String action = "coreinner.getPet";
		final PlayerAsyncRequestListener<PersistPlayerPet> listener = new PlayerAsyncRequestListener<PersistPlayerPet>() {
			@Override
			protected void handleResponse(PersistPlayerPet playerPet) {
				Pet pet = Pet.get(playerPet.getCharactorId());
				if (pet.getCompanyLevel() > player.getGrade()) {
					errorResponse(new GeneralException(AppErrorCodes.JOIN_BATTLE_PET_GRADE, playerPet.getName(), pet.getCompanyLevel()));
					return;
				}
				if (pet.getLifePoint() > 0 && playerPet.getLifePoint() <= PersistPlayerPet.joinBattleMinLife()) {
					errorResponse(new GeneralException(AppErrorCodes.PET_LIFE_NOT_ENOUGH_TO_FIGHT));
					return;
				}

				Battle battle = checkBattle(player, round, battleId);
				BattleInfo battleInfo = battle.battleInfo();
				BattleTeam myTeam = battleInfo.myTeam(player.getId());

				BattlePlayerSoldierInfo playerSoldiersInfo = myTeam.soldiersByPlayer(player.getId());
				if (null == playerSoldiersInfo) {
					errorResponse(new GeneralException(AppErrorCodes.BATTLE_SOLDIER_NOT_EXIST));
					return;
				}
				BattleSoldier trigger = myTeam.soldier(playerSoldiersInfo.battleSoldierByInd(true));
				if (null != trigger.getCommandContext()) {
					errorResponse(new GeneralException(AppErrorCodes.BATTLE_SKILL_COMMAND_EXIST));
					return;
				}
				Skill skill = trigger.skillHolder().activeSkill(SUMMON_SKILL_ID);
				if (null == skill) {
					errorResponse(new GeneralException(AppErrorCodes.BATTLE_SKILL_NOT_EXIST));
					return;
				}
				CommandContext commandContext = new CommandContext(trigger, skill, null, petUniqueId);
				commandContext.setCachedBattlePet(playerPet);
				trigger.setAutoBattle(false);
				trigger.initCommandContext(commandContext);

				readyNotify(trigger);
				successResponse();
			}
		};
		if (CrossServerUtils.isCrossSceneServer()) {
			sceneModeService.toInner().async(listener, mode, player.onlineGameServerId(), action, player.getId(), petUniqueId);
		} else {
			sceneModeService.toInner().async(listener, mode, action, player.getId(), petUniqueId);
		}
	}

	public void changeChild(ScenePlayer player, long battleId, long childUniqueId, int round) {
		int toClientId = CrossServerUtils.isCrossSceneServer() ? player.onlineGameServerId() : 1;
		// 异步先取宠物回来, 缓存到换宠技能使用
		sceneModeService.toInner().async(new PlayerAsyncRequestListener<PersistPlayerChild>() {
			@Override
			protected void handleResponse(PersistPlayerChild playerChild) {
				if (playerChild == null)
					return;
				Child child = playerChild.child();
				if (child.getCompanyLevel() > player.getGrade()) {
					errorResponse(new GeneralException(AppErrorCodes.JOIN_BATTLE_PET_GRADE, playerChild.getName(), child.getCompanyLevel()));
					return;
				}
				Battle battle = checkBattle(player, round, battleId);
				BattleInfo battleInfo = battle.battleInfo();
				BattleTeam myTeam = battleInfo.myTeam(player.getId());

				BattlePlayerSoldierInfo playerSoldiersInfo = myTeam.soldiersByPlayer(player.getId());
				if (null == playerSoldiersInfo) {
					errorResponse(new GeneralException(AppErrorCodes.BATTLE_SOLDIER_NOT_EXIST));
					return;
				}
				BattleSoldier trigger = myTeam.soldier(playerSoldiersInfo.battleSoldierByInd(true));
				if (null != trigger.getCommandContext()) {
					errorResponse(new GeneralException(AppErrorCodes.BATTLE_SKILL_COMMAND_EXIST));
					return;
				}
				Skill skill = trigger.skillHolder().activeSkill(SUMMON_SKILL_ID);
				if (null == skill) {
					errorResponse(new GeneralException(AppErrorCodes.BATTLE_SKILL_NOT_EXIST));
					return;
				}
				CommandContext commandContext = new CommandContext(trigger, skill, null, childUniqueId);
				commandContext.setCachedBattleChild(playerChild);
				trigger.setAutoBattle(false);
				trigger.initCommandContext(commandContext);

				readyNotify(trigger);
				successResponse();
			}
		}, AppServerMode.Core.ordinal(), toClientId, "coreinner.getChild", player.getId(), childUniqueId);
	}

	private void autoBattle(BattleSoldier target, boolean isAuto) {
		if (null == target)
			return;
		if (isAuto) {
			// target.autoBattle();
			target.initCommandContextIfAbsent();
			target.setAutoBattle(true);
			readyNotify(target);
		} else {
			target.setAutoBattle(false);
			target.destoryCommandContext();
		}
	}

	private Battle checkBattle(ScenePlayer player, int round, long battleId) {
		Battle battle = battleManager.get(battleId);
		if (null == battle)
			throw new GeneralException(AppErrorCodes.BATTLE_ID_NOT_FOUND);
		if (!battle.battleInfo().hasJoin(player.getId()))
			throw new GeneralException(AppErrorCodes.BATTLE_NOT_JOIN);
		if (round > 0 && round != battle.getCount())
			throw new GeneralException(AppErrorCodes.BATTLE_COMMAND_ROUND_NO_MATCH);
		battle.checkStart();
		return battle;
	}

	/**
	 * 指挥
	 * 
	 * @param player
	 * @param battleId
	 * @param targetSoldierId
	 * @param command
	 */
	public void order(ScenePlayer player, long battleId, long targetSoldierId, String command, boolean clearAll) {
		Battle battle = battleManager.get(battleId);
		if (null == battle)
			throw new GeneralException(AppErrorCodes.BATTLE_ID_NOT_FOUND);
		if (player.ifTeamLeader() || player.isCommander()) {
			BattleTeam myTeam = battle.battleInfo().myTeam(player.getId());
			List<Long> excludePlayerIds = myTeam.getEnemyTeam().playerIds();
			battle.broadcast(new CommandNotify(targetSoldierId, command, clearAll), excludePlayerIds.toArray(new Long[] {}));
		} else
			throw new GeneralException(AppErrorCodes.CANNOT_ORDER);
	}

	public void roundReady(ScenePlayer player, long battleId) {
		Battle battle = battleManager.get(battleId);
		if (battle == null)
			throw new GeneralException(AppErrorCodes.BATTLE_ID_NOT_FOUND);
		battle.manualRoundReady(player.getId());
	}
}
