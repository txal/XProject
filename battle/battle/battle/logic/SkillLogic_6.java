package com.nucleus.logic.core.modules.battle.logic;

import java.util.HashSet;
import java.util.List;
import java.util.Set;

import org.apache.commons.collections.CollectionUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import com.nucleus.AppServerMode;
import com.nucleus.commons.data.StaticConfig;
import com.nucleus.commons.exception.GeneralException;
import com.nucleus.commons.utils.RandomUtils;
import com.nucleus.logic.core.modules.AppErrorCodes;
import com.nucleus.logic.core.modules.AppStaticConfigs;
import com.nucleus.logic.core.modules.assistskill.data.AssistSkill.AssistSkillEnum;
import com.nucleus.logic.core.modules.assistskill.model.PersistPlayerAssistSkill;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.dto.BattleSceneNotify;
import com.nucleus.logic.core.modules.battle.dto.VideoRetreatState;
import com.nucleus.logic.core.modules.battle.manager.BattleManager;
import com.nucleus.logic.core.modules.battle.model.Battle;
import com.nucleus.logic.core.modules.battle.model.BattlePlayer;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.BattleTeam;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.charactor.data.ShoutConfig;
import com.nucleus.logic.core.modules.glory.GloryFightBattle;
import com.nucleus.logic.core.modules.player.dto.PlayerDto;
import com.nucleus.logic.core.modules.scene.manager.ScenePlayerManager;
import com.nucleus.logic.core.modules.scene.model.Scene;
import com.nucleus.logic.core.modules.scene.model.SceneMineBattle;
import com.nucleus.logic.core.modules.scene.model.ScenePlayer;
import com.nucleus.logic.core.modules.team.PlayerTeamStatusManager;
import com.nucleus.logic.core.modules.team.dto.PlayerTeamStatusChangeNotify;
import com.nucleus.logic.core.modules.team.event.PlayerTeamStatusPostListener;
import com.nucleus.logic.scene.SceneModeService;
import com.nucleus.logic.scene.cross.CrossServerUtils;
import com.nucleus.logic.scene.cross.CrossTeamManager;
import com.nucleus.player.model.PlayerAsyncRequestListener;

/**
 * 撤退
 *
 * @author liguo
 */
@Service
public class SkillLogic_6 extends SkillLogicAdapter {
	@Autowired
	private SceneModeService sceneModeService;
	@Autowired
	private BattleManager battleManager;
	@Value("${whole.inner.id}")
	private int wholeClientId;
	@Autowired
	private CrossTeamManager crossTeamManager;

	@Override
	public void doFired(CommandContext commandContext) {
		BattleSoldier trigger = commandContext.trigger();
		Battle battle = commandContext.battle();
		if (battle instanceof GloryFightBattle)
			throw new GeneralException(AppErrorCodes.GLOEY_BATTLE_CANNOT_ESCAPE);

		boolean success = trigger.forceLeaveBattle();
		float rate = 1.0f;
		if (!success) {
			if (commandContext.isAutoEscapeable()) {// 宠物自动逃跑的情况下成功率读取指定配置
				rate = battle.petAutoEscapeSuccessRate();
			} else {
				rate = battle.retreatSuccessRate();
				float maxRate = StaticConfig.get(AppStaticConfigs.MAX_RETREAT_SUCCESS_RATE).getAsFloat(0.9f);
				float minRate = StaticConfig.get(AppStaticConfigs.MIN_RETREAT_SUCCESS_RATE).getAsFloat(0.2f);
				rate = assistSkillEffect(trigger, rate);
				commandContext.setRetreatSuccessRate(rate);
				trigger.skillHolder().passiveSkillEffectByTiming(trigger, commandContext, PassiveSkillLaunchTimingEnum.BeforeEscape);
				rate = commandContext.getRetreatSuccessRate();
				rate -= trigger.team().getRetreateReducceRate();
				rate = Math.min(rate, maxRate);
				rate = Math.max(rate, minRate);
			}
			success = RandomUtils.baseRandomHit(rate);
		}
		VideoRetreatState retreatState = new VideoRetreatState(trigger, success, rate);
		commandContext.skillAction().addTargetState(retreatState);
		if (success) {
			if (trigger.ifPet()) {
				trigger.shout(ShoutConfig.BattleShoutTypeEnum.RunAway, commandContext);
			}
			BattleTeam team = trigger.battleTeam();
			boolean mainCharactor = trigger.ifMainCharactor();
			Set<Long> retreatSoldierHolder = new HashSet<>();
			team.onRetreat(trigger, retreatSoldierHolder, true);// 一次性把跟玩家相关的战斗单位都撤退,包括宠物，伙伴，召唤怪
			retreatState.setRetreatSoldiers(retreatSoldierHolder);
			if (mainCharactor) {
				long playerId = trigger.playerId();
				// 这里玩家虽然撤退,但要把玩家id暂存下来,因为还要发送给该客户端玩家最后一次撤退指令,发送完后则清除,不再收到战斗通知
				battle.addRetreatPlayerId(playerId);
				battleManager.removeByPlayerId(playerId);
				// 队长撤退
				boolean isLeader = team.ifPlayerLeader(playerId);
				if (isLeader) {
					if (battle instanceof SceneMineBattle)
						((SceneMineBattle) battle).resetMeet(playerId);
				}
				// 玩家退完,战斗结束
				if (team.playerIds().isEmpty()) {
					notifyScene(false, playerId);
					battleManager.over(battle);
					trigger.retreatCallbackHandle();
					trigger.battleFinishCallbackHandle();
				} else {
					final Set<Long> leftPlayerIds = team.inBattlePlayerIds();
					long[] aryLeftPlayerIds = new long[leftPlayerIds.size()];
					int i = 0;
					for (long pId : leftPlayerIds) {
						aryLeftPlayerIds[i++] = pId;
					}
					// Fixed #8175
					// 逃跑时设置一个队员变更的监听, 组队状态变化后才发BattleSceneNotify
					setPlayerTeamStatusPostListener(playerId, isLeader, aryLeftPlayerIds, trigger);
					afterRetreatTeamStateHandle(team, playerId);
				}
			}
		}
	}

	/**
	 * 战斗撤退后组队状态操作
	 * 
	 * @param team
	 * @param playerId
	 */
	private void afterRetreatTeamStateHandle(BattleTeam team, long playerId) {
		if (CrossServerUtils.isCrossSceneServer()) {
			long newLeaderId = crossTeamManager.battleTeamAway(playerId);
			if (newLeaderId > 0)
				team.setLeaderId(newLeaderId);
			return;
		}
		sceneModeService.toInner().async(new PlayerAsyncRequestListener<Long>() {
			@Override
			protected void handleResponse(Long newLeaderId) {
				// 更新状态,并返回队长id
				if (newLeaderId != 0) {
					team.setLeaderId(newLeaderId);
				}
			}
		}, AppServerMode.Whole.ordinal(), wholeClientId, "wholeinner.battleTeamAway", playerId);
	}

	/**
	 * 逃离/追捕技能效果
	 *
	 * @param trigger
	 * @param originalValue
	 * @return
	 */
	private float assistSkillEffect(BattleSoldier trigger, float originalValue) {
		if (trigger.playerId() <= 0 || trigger.ifPet())
			return originalValue;
		try {
			BattlePlayer triggerPlayer = trigger.player();
			if (triggerPlayer == null)
				return originalValue;
			// 触发者判断自己是否有逃离辅助技能
			// PersistPlayerAssistSkill ppas = PlayerAssistSkillHolderManager.getInstance().load(triggerPlayer);
			PersistPlayerAssistSkill ppas = triggerPlayer.persistPlayerAssistSkill();
			float effectValue = ppas.effectValue(AssistSkillEnum.Escape);
			originalValue += effectValue;
			// 判断对方leader是否有追捕技能
			BattlePlayer enemyLeader = trigger.battleTeam().getEnemyTeam().leader();// 对方leader
			if (enemyLeader != null) {
				// ppas = PlayerAssistSkillHolderManager.getInstance().load(enemyLeader);
				ppas = enemyLeader.persistPlayerAssistSkill();
				originalValue += ppas.effectValue(AssistSkillEnum.Pursuit);
			}
		} catch (Exception e) {
			e.printStackTrace();
		}
		return originalValue;
	}

	private void setPlayerTeamStatusPostListener(long playerId, boolean isLeader, long[] aryLeftPlayerIds, BattleSoldier trigger) {
		PlayerTeamStatusManager.getInstance().once(new EscapeTeamStatusChangePostListener(playerId, isLeader, aryLeftPlayerIds, trigger));
	}

	public static void notifyScene(boolean inBattle, long... playerIds) {
		if (playerIds.length <= 0)
			return;
		final ScenePlayer player = ScenePlayerManager.getInstance().get(playerIds[0]);
		if (player == null)
			return;
		Scene scene = player.currentScene();
		if (scene != null) {
			scene.screenBroadcast(player, new BattleSceneNotify(inBattle, playerIds));
		}
	}

	public static class EscapeTeamStatusChangePostListener implements PlayerTeamStatusPostListener {

		protected long playerId;
		protected boolean leader;
		protected long[] aryLeftPlayerIds;
		private BattleSoldier trigger;

		public EscapeTeamStatusChangePostListener(long playerId, boolean isLeader, long[] aryLeftPlayerIds, BattleSoldier trigger) {
			this.playerId = playerId;
			this.leader = isLeader;
			this.aryLeftPlayerIds = aryLeftPlayerIds;
			this.trigger = trigger;
		}

		@Override
		public boolean match(PlayerTeamStatusChangeNotify statusChangeNotify) {
			final List<Long> playerIds = statusChangeNotify.getPlayerIds();
			final List<Integer> statuses = statusChangeNotify.getTeamStatuses();
			if (CollectionUtils.isEmpty(playerIds) || CollectionUtils.isEmpty(statuses))
				return false;
			if (playerIds.contains(playerId) && statuses.contains(PlayerDto.PlayerTeamStatus.Away.ordinal())) {
				return true;
			}
			return false;
		}

		@Override
		public void onStatusChange(PlayerTeamStatusChangeNotify statusChangeNotify) {
			// 离队了, 逃跑的队员广播
			notifyScene(false, playerId);
			// 如果逃跑的是队长, 会影响整队人看到的人不在战斗中, 所以重新对剩下的人广播一次BattleSceneNotify
			if (leader && aryLeftPlayerIds.length > 0) {
				final ScenePlayer player = ScenePlayerManager.getInstance().get(aryLeftPlayerIds[0]);
				if (player != null && BattleManager.getInstance().ifInBattle(player.getId())) {
					notifyScene(true, aryLeftPlayerIds);
				}
			}
			if (trigger != null) {
				trigger.retreatCallbackHandle();
				trigger.battleFinishCallbackHandle();
			}
		}
	}
}
