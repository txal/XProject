/**
 * 
 */
package com.nucleus.logic.core.modules.battle.manager;

import java.util.Iterator;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

import javax.annotation.PostConstruct;

import org.apache.commons.lang3.time.DateUtils;
import org.apache.commons.logging.Log;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import com.eclipsesource.v8.utils.V8Thread;
import com.google.common.collect.ImmutableSet;
import com.nucleus.AppServerMode;
import com.nucleus.commons.data.StaticConfig;
import com.nucleus.commons.health.Monitor;
import com.nucleus.commons.timer.AppScheduleManager;
import com.nucleus.commons.utils.SpringUtils;
import com.nucleus.logic.AppCommonUtils;
import com.nucleus.logic.core.modules.AppStaticConfigs;
import com.nucleus.logic.core.modules.barrage.model.BarrageService;
import com.nucleus.logic.core.modules.battle.dto.BattleSceneNotify;
import com.nucleus.logic.core.modules.battle.dto.BattleWatchDto;
import com.nucleus.logic.core.modules.battle.dto.Video;
import com.nucleus.logic.core.modules.battle.dto.VideoSoldier;
import com.nucleus.logic.core.modules.battle.dto.VideoTeam;
import com.nucleus.logic.core.modules.battle.model.Battle;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.BattleTeam;
import com.nucleus.logic.core.modules.player.dto.PlayerDto;
import com.nucleus.logic.core.modules.scene.manager.SceneManager;
import com.nucleus.logic.core.modules.scene.manager.ScenePlayerManager;
import com.nucleus.logic.core.modules.scene.model.Scene;
import com.nucleus.logic.core.modules.scene.model.ScenePlayer;
import com.nucleus.logic.core.modules.timer.LogicScheduleManager;
import com.nucleus.logic.scene.SceneModeService;
import com.nucleus.outer.msg.GeckoMultiMessage;

/**
 * @author liguo
 * 
 */
@Service
public class BattleManager implements Monitor {

	/** 所有战斗 */
	private final Map<Long, BattleElement> battleMap = new ConcurrentHashMap<Long, BattleElement>();

	/** 所有战斗by玩家编号 */
	private final Map<Long, Long> battleIdsMapByPlayerId = new ConcurrentHashMap<Long, Long>();

	/** 观战玩家ID <-> 被观战玩家ID **/
	private final Map<Long, Long> watchBattlePlayerIds = new ConcurrentHashMap<>();

	@Autowired
	private LogicScheduleManager logicScheduleManager;

	@Autowired
	private AppScheduleManager appScheduleManager;

	@Autowired
	private SceneModeService sceneModeService;

	@Value("${v8.runtime.maxtimes:300}")
	private int maxTimes;

	@PostConstruct
	public void init() {
		if (!AppCommonUtils.isValidMode(AppServerMode.Scene.name())) {
			return;
		}
		appScheduleManager.scheduleAtFixedRate(new BattleCheckTask(), 0, 500);
	}

	public static BattleManager getInstance() {
		return SpringUtils.getBeanOfType(BattleManager.class);
	}

	@Override
	public void out(Log healthLog) {
		healthLog.info("********" + getClass().getSimpleName() + " Health Info ********");
		healthLog.info("\tbattleCount:" + battleMap.size());
	}

	/**
	 * 返回已存在战斗
	 * 
	 * @param playerId
	 * @return
	 */
	public Video existingBattle(long playerId) {
		Video video = null;
		Battle curBattle = battleByPlayer(playerId);
		if (null != curBattle) {
			// over(curBattle);
			curBattle.broadcastSceneInBattle(true);
			video = curBattle.getVideo();
			if (video != null)
				battle2Video(curBattle, video);
		}
		return video;
	}

	/**
	 * 同步战斗状态
	 * 
	 * @param curBattle
	 * @param video
	 */
	private void battle2Video(Battle curBattle, Video video) {
		video.setCurrentRound(curBattle.getCount());
		long now = System.currentTimeMillis();
		int manualRemain = (int) ((curBattle.curManualNotifyTime() - now) / DateUtils.MILLIS_PER_SECOND);
		manualRemain = manualRemain < 0 ? 0 : manualRemain;
		video.setCurrentRoundCommandOptRemainSec(manualRemain);
		BattleTeam aTeam = curBattle.battleInfo().getAteam();
		BattleTeam bTeam = curBattle.battleInfo().getBteam();
		restoreTeam(aTeam, video.getAteam());
		restoreTeam(bTeam, video.getBteam());
		curBattle.initPetsOfPlayer();
	}

	private void restoreTeam(BattleTeam team, VideoTeam videoTeam) {
		videoTeam.getPlayerIds().clear();
		videoTeam.getPlayerIds().addAll(team.playerIds());
		for (Iterator<VideoSoldier> it = videoTeam.getTeamSoldiers().iterator(); it.hasNext();) {
			VideoSoldier vs = it.next();
			BattleSoldier soldier = team.soldier(vs.getId());
			if (soldier == null) {
				it.remove();
				continue;
			}
			vs.restoreState(soldier);
		}
	}

	/**
	 * 观战
	 * 
	 * @param playerId
	 *            战斗中的某个玩家编号
	 * @param watchPlayerId
	 *            观点玩家编号
	 * @param notify
	 * @return
	 */
	public BattleWatchDto watchBattle(long playerId, long watchPlayerId, boolean notify) {
		final Set<Long> watchPlayerIds = ImmutableSet.of(watchPlayerId);
		Battle curBattle = battleByPlayer(playerId);
		if (curBattle == null) {
			Long beWatchPlayerId = getBeWatchPlayerId(playerId);
			if (beWatchPlayerId != null) {
				return watch(beWatchPlayerId, watchPlayerIds, notify);
			}
		} else {
			return watch(playerId, watchPlayerIds, notify);
		}
		return null;
	}

	public BattleWatchDto watch(long playerId, final Set<Long> watchPlayerIds, final boolean notify) {
		Battle battle = battleByPlayer(playerId);
		if (battle == null)
			return null;
		int battleTeamId = battle.joinWatch(playerId, watchPlayerIds);
		addWatchPlayerIds(playerId, watchPlayerIds);
		final BattleWatchDto dto = new BattleWatchDto();
		if (battle.getVideo() != null)
			battle2Video(battle, battle.getVideo());
		dto.setVideo(battle.getVideo());
		dto.setWatchTeamId(battleTeamId);
		if (notify) {
			sceneModeService.toOuter().send(new GeckoMultiMessage(dto, watchPlayerIds));
		}
		// 通知进入战斗状态
		battleSceneNotify(playerId, true, watchPlayerIds);
		return dto;
	}
	
	public BattleWatchDto watch(long playerId, long battleId, final Set<Long> watchPlayerIds, final boolean notify) {
		Battle battle = get(battleId);
		if (battle == null)
			return null;
		int battleTeamId = battle.joinWatch(playerId, watchPlayerIds);
		addWatchPlayerIds(playerId, watchPlayerIds);
		final BattleWatchDto dto = new BattleWatchDto();
		if (battle.getVideo() != null)
			battle2Video(battle, battle.getVideo());
		dto.setVideo(battle.getVideo());
		dto.setWatchTeamId(battleTeamId);
		if (notify) {
			sceneModeService.toOuter().send(new GeckoMultiMessage(dto, watchPlayerIds));
		}
		// 通知进入战斗状态
		battleSceneNotify(playerId, true, watchPlayerIds);
		return dto;
	}

	public boolean watchExit(long battleId, final Set<Long> exitWatchPlayerIds, final boolean notify) {
		Battle curBattle = this.get(battleId);
		if (null != curBattle) {
			curBattle.exitWatch(exitWatchPlayerIds, notify);
			removeWatchPlayerIds(exitWatchPlayerIds);
			// 通知退出战斗状态
			final long playerId = curBattle.battleInfo().getAteam().leaderId();
			battleSceneNotify(playerId, false, exitWatchPlayerIds);
			return true;
		}
		return false;
	}

	private void battleSceneNotify(final long battlePlayerId, final boolean inBattle, final Set<Long> playerIds) {
		ScenePlayer watchByPlayer = ScenePlayerManager.getInstance().get(battlePlayerId);
		if (watchByPlayer != null) {
			final BattleSceneNotify battleSceneNotify = new BattleSceneNotify(inBattle, playerIds);
			Scene scene = SceneManager.getInstance().getScene(watchByPlayer.getSceneId());
			scene.screenBroadcast(watchByPlayer, battleSceneNotify);
		}
	}

	public Long getBeWatchPlayerId(long playerId) {
		return this.watchBattlePlayerIds.get(playerId);
	}

	public void addWatchPlayerIds(long playerId, final Set<Long> watchPlayerIds) {
		for (Long watchPlayerId : watchPlayerIds) {
			this.watchBattlePlayerIds.put(watchPlayerId, playerId);
		}
	}

	public void removeWatchPlayerIds(final Set<Long> watchPlayerIds) {
		for (Long watchPlayerId : watchPlayerIds) {
			this.watchBattlePlayerIds.remove(watchPlayerId);
		}
	}

	public long battleIdOfPlayer(long playerId) {
		Long battleId = battleIdsMapByPlayerId.get(playerId);
		if (battleId == null)
			return 0;
		Battle battle = get(battleId);
		return battle == null ? 0 : battle.getId();
	}

	public Battle battleByPlayer(long playerId) {
		Battle battle = null;
		Long battleId = battleIdsMapByPlayerId.get(playerId);
		if (null == battleId) {
			return battle;
		}

		battle = get(battleId);
		if (null == battle) {
			battleIdsMapByPlayerId.remove(playerId);
		}

		return battle;
	}

	public boolean ifInBattle(long playerId) {
		return null != battleByPlayer(playerId);
	}

	public void ready(Battle battle) {
		if (battle == null)
			return;
		battleMap.put(battle.getId(), new BattleElement(battle));

		long battleId = battle.getId();
		for (long playerId : battle.allPlayerIds()) {
			battleIdsMapByPlayerId.put(playerId, battleId);
		}
		if (battle.getLog().isDebugEnabled())
			battle.getLog().debug(battle.getId() + ">>>start battle id:" + battle.getId());
	}

	public void removeByPlayerId(long playerId) {
		this.battleIdsMapByPlayerId.remove(playerId);
	}

	public void over(Battle battle) {
		if (battle == null)
			return;
		battle.broadcastSceneInBattle(false);
		battleMap.remove(battle.getId());
		if (battle.getLog().isDebugEnabled())
			battle.getLog().debug(battle.getId() + ">>>battle id over:" + battle.getId() + ",winId:" + battle.getVideo().getWinId());

		// 清理观看者
		checkAndNotifyWatchers(battle);

		// 战斗结束清空弹幕信息
		BarrageService.getInstance().removeBattleOrWeddingOver(battle.getId());
		battle.clear();
	}

	private void checkAndNotifyWatchers(Battle battle) {
		final Set<Long> watchPlayerIds = battle.battleInfo().watchList();
		if (watchPlayerIds != null && !watchPlayerIds.isEmpty()) {
			long playerId = battle.battleInfo().getAteam().leaderId();
			if (playerId <= 0) {
				// 这里如果玩家逃跑,没有leaderPlayerId了,就用观战玩家去向场景广播
				playerId = watchPlayerIds.iterator().next();
			}
			removeWatchPlayerIds(watchPlayerIds);
			battleSceneNotify(playerId, false, watchPlayerIds);
		}
	}

	/**
	 * 获取战斗时并改变访问时间，增加游戏的生命周期
	 * 
	 * @param battleId
	 * @return
	 */
	public Battle get(long battleId) {
		return get0(battleId, true);
	}

	/**
	 * 是否存在战斗
	 * 
	 * @param battleId
	 * @return
	 */
	public Battle has(long battleId) {
		return get0(battleId, false);
	}

	private Battle get0(long battleId, boolean delay) {
		BattleElement element = battleMap.get(battleId);
		if (element == null) {
			return null;
		}

		if (element.inIdle()) {
			over(element.getBattle());
			return null;
		}

		if (delay) {
			element.setRecentAccessTime(System.currentTimeMillis());
		}
		return element.getBattle();
	}

	private class BattleCheckTask implements Runnable {
		@Override
		public void run() {
			long now = System.currentTimeMillis();
			for (Iterator<BattleElement> it = battleMap.values().iterator(); it.hasNext();) {
				BattleElement element = it.next();
				if (element.inIdle()) {
					over(element.getBattle());
					continue;
				}
				if (!element.battle.checkNotifyStart(now))
					continue;
				BattleRoundTask task = element.ready();
				if (task == null)
					continue;
				logicScheduleManager.schedule(task, 0);
			}
		}

	}

	private class BattleRoundTask implements Runnable {
		private volatile boolean running = false;
		private BattleElement battleElement;

		public BattleRoundTask(BattleElement battleElement) {
			this.battleElement = battleElement;
		}

		@Override
		public void run() {
			try {
				battleElement.battle.roundStart();
			} finally {
				running = false;
				if (Thread.currentThread() instanceof V8Thread)
					((V8Thread) Thread.currentThread()).releaseV8(maxTimes);
			}
		}
	}

	public BattleWatchDto checkBattle(ScenePlayer player, long leaderPlayerId, boolean notify) {
		Video video = existingBattle(player.getId());
		BattleWatchDto watchDto = null;
		if (video != null) {
			video.setSerial(0);
			if (notify) {
				player.deliver(video);
			} else {
				watchDto = new BattleWatchDto(0, video);
			}
		}
		if (watchDto == null && leaderPlayerId > 0 && player.teamStatus() == PlayerDto.PlayerTeamStatus.Member) {
			watchDto = watchBattle(leaderPlayerId, player.getId(), notify);
		}
		return watchDto;
	}

	class BattleElement {
		private BattleRoundTask battleRoundTask;
		private Battle battle;
		private long recentAccessTime;
		private long createTime;

		public BattleElement(Battle battle) {
			this.battle = battle;
			this.recentAccessTime = System.currentTimeMillis();
			this.createTime = this.recentAccessTime;
			this.battleRoundTask = new BattleRoundTask(this);
		}

		public BattleRoundTask ready() {
			if (running())
				return null;
			return battleRoundTask;
		}

		public Battle getBattle() {
			this.recentAccessTime = System.currentTimeMillis();
			return battle;
		}

		private boolean running() {
			return battleRoundTask.running;
		}

		public void setBattle(Battle battle) {
			this.battle = battle;
		}

		public long getRecentAccessTime() {
			return recentAccessTime;
		}

		public void setRecentAccessTime(long recentAccessTime) {
			this.recentAccessTime = recentAccessTime;
		}

		public long getCreateTime() {
			return createTime;
		}

		public void setCreateTime(long createTime) {
			this.createTime = createTime;
		}

		public boolean inIdle() {
			return (System.currentTimeMillis() - recentAccessTime) >= StaticConfig.get(AppStaticConfigs.BATTLE_CACHE_TIME).getAsInt(1800000);
		}
	}
}
