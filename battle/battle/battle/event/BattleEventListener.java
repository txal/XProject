package com.nucleus.logic.core.modules.battle.event;

import org.apache.commons.collections.CollectionUtils;
import org.springframework.stereotype.Service;

import com.nucleus.commons.data.StaticConfig;
import com.nucleus.commons.data.TraceType;
import com.nucleus.logic.core.modules.AppStaticConfigs;
import com.nucleus.logic.core.modules.AppTraceTypes;
import com.nucleus.logic.core.modules.challenge.event.ChallengeBonusEvent;
import com.nucleus.logic.core.modules.equipment.event.LoseDurationEvent;
import com.nucleus.logic.core.modules.mission.manager.PlayerMissionManager;
import com.nucleus.logic.core.modules.player.data.StateBar;
import com.nucleus.logic.core.modules.player.dto.TransformCardSateBarDto;
import com.nucleus.logic.core.modules.player.event.TransfromStateEvent;
import com.nucleus.logic.core.modules.player.manager.PlayerTransformManager;
import com.nucleus.logic.core.modules.player.model.CorePlayer;
import com.nucleus.logic.core.modules.player.model.PersistPlayer;
import com.nucleus.logic.core.modules.player.model.PersistPlayerTransform;
import com.nucleus.logic.core.modules.reward.data.FallReward;
import com.nucleus.logic.core.modules.scene.data.SceneMap;
import com.nucleus.logic.core.modules.scene.event.MineBattleWinEvent;
import com.nucleus.logic.core.modules.siege.SiegeBattleService;
import com.nucleus.logic.core.modules.siege.event.SiegeBattleEndEvent;
import com.nucleus.player.event.PlayerEvent;
import com.nucleus.player.event.PlayerEventListener;

/**
 * 战斗事件监听器
 * <p>
 * Created by Tony on 15/7/14.
 */
@Service
public class BattleEventListener implements PlayerEventListener {
	@Override
	public void onEvent(PlayerEvent event) {
		if (!(event instanceof BattleEvent)) {
			return;
		}
		CorePlayer corePlayer = (CorePlayer) event.getDispatcher();
		final Object evtMessage = ((BattleEvent) event).getEvtMessage();

		if (evtMessage instanceof ChallengeBonusEvent) {
			ChallengeBonusEvent bonusEvent = (ChallengeBonusEvent) evtMessage;
			TraceType traceType = TraceType.get(AppTraceTypes.CHALLENGE_BONUS);
			corePlayer.reward(traceType, "ChallengeBonus", bonusEvent.getExp(), bonusEvent.getPetExp(), bonusEvent.getCopper(), 0, 0, bonusEvent.getScore(), 0, 0, null);

		} else if (evtMessage instanceof MineBattleWinEvent) {
			MineBattleWinEvent mineBattleWinEvent = (MineBattleWinEvent) evtMessage;
			SceneMap sceneMap = SceneMap.get(mineBattleWinEvent.getSceneId());
			if (sceneMap.getFallItemRate() > 0 && sceneMap.getFallRewardId() > 0) {
				TraceType traceType = TraceType.get(AppTraceTypes.MINE_BATTLE_GAIN);
				FallReward fallReward = FallReward.get(sceneMap.getFallRewardId());
				long exp = mineBattleWinEvent.getExp();
				if (mineBattleWinEvent.isLeaerBonus()) {
					// 队长经验加成显示
					float rate = StaticConfig.get(AppStaticConfigs.LEADER_RATE).getAsFloat(0.3f);
					long leaderExp = (long) (exp * rate);
					corePlayer.leaderExp(leaderExp);
				}
				if (fallReward != null)
					fallReward.done(corePlayer, traceType, mineBattleWinEvent.getDesc(), exp, mineBattleWinEvent.getPetExp(), 0, mineBattleWinEvent.getCopper(), mineBattleWinEvent.getFallItemRate(), true, false);
			}

			int levelLimit = sceneMap.getLevelLimit();
			int playerLevel = corePlayer.getGrade();
			if (CollectionUtils.isNotEmpty(sceneMap.getMonsterIds()) && (playerLevel >= levelLimit) && (playerLevel < (levelLimit + 10))) {
				PlayerMissionManager.getInstance().createIfAbsent(corePlayer).playerChainMissionHolder().legendFallReward();
			}
		} else if (evtMessage instanceof SiegeBattleEndEvent) {
			SiegeBattleEndEvent siegeBattleEndEvent = (SiegeBattleEndEvent) evtMessage;
			SiegeBattleService.getInstance().onBattleFinish(corePlayer, siegeBattleEndEvent.getTownId(), siegeBattleEndEvent.getDifficulty(), siegeBattleEndEvent.isWin());
		} else if (evtMessage instanceof TransfromStateEvent) {
			final boolean pvp = ((TransfromStateEvent) evtMessage).isPvp();
			if (pvp) {
				PersistPlayerTransform ppt = PlayerTransformManager.getInstance().createIfAbsent(corePlayer);
				if (!ppt.expired()) {
					ppt.decreasePvpTimes();
					if (!corePlayer.isConnected())
						ppt.update();
					else if (ppt.getPvpTimes() > 0) {
						StateBar sb = StateBar.get(StateBar.TRANSFORM_CARD);
						TransformCardSateBarDto sateDto = new TransformCardSateBarDto(ppt, sb);
						corePlayer.deplayDeliver(sateDto);
					}
				}
			}
		} else if (evtMessage instanceof LoseDurationEvent) {
			LoseDurationEvent loseDurationEvent = (LoseDurationEvent) evtMessage;
			PersistPlayer persistPlayer = corePlayer.persistPlayer();
			persistPlayer.propertyHolder().loseDuration(loseDurationEvent.getAttackTimes(), loseDurationEvent.getBeAttackTimes(), loseDurationEvent.isDeadReduce());
		}
	}
}
