/**
 * 
 */
package com.nucleus.logic.core.modules.battle.model;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Date;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.function.Consumer;
import java.util.function.Predicate;

import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;
import org.apache.commons.lang3.time.DateUtils;

import com.nucleus.AppServerMode;
import com.nucleus.commons.data.StaticConfig;
import com.nucleus.commons.exception.GeneralException;
import com.nucleus.commons.message.TerminalMessage;
import com.nucleus.commons.utils.IdUtils;
import com.nucleus.commons.utils.JsonUtils;
import com.nucleus.logic.core.modules.AppErrorCodes;
import com.nucleus.logic.core.modules.AppStaticConfigs;
import com.nucleus.logic.core.modules.battle.data.Monster;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.dto.BattlePlayerInfoDto;
import com.nucleus.logic.core.modules.battle.dto.BattleRoundReadyNotify;
import com.nucleus.logic.core.modules.battle.dto.BattleSceneNotify;
import com.nucleus.logic.core.modules.battle.dto.BattleWatchExit;
import com.nucleus.logic.core.modules.battle.dto.Video;
import com.nucleus.logic.core.modules.battle.dto.VideoRound;
import com.nucleus.logic.core.modules.battle.event.BattleEvent;
import com.nucleus.logic.core.modules.battle.manager.BattleManager;
import com.nucleus.logic.core.modules.equipment.event.LoseDurationEvent;
import com.nucleus.logic.core.modules.scene.manager.SceneManager;
import com.nucleus.logic.core.modules.scene.model.Scene;
import com.nucleus.logic.core.vo.BattleFinishVo;
import com.nucleus.logic.scene.SceneModeService;
import com.nucleus.outer.msg.GeckoMultiMessage;

/**
 * @author liguo
 * 
 */
public abstract class BattleAdapter extends AbstractBattle {
	/** 战斗编号 */
	private long id;
	/** 回合数 */
	private int count;
	/** 是否强制战斗结束，设置为true时务必设置胜利方 */
	private boolean forceOver;
	/** 战斗信息 */
	private BattleInfo battleInfo;
	/** 战斗Video */
	private Video video;
	/** 战斗回合处理器 */
	private BattleRoundProcessor battleRoundProcessor;
	/** 回合开始时间点(deadline) */
	protected volatile long roundStartTime;
	/** 未修正之前的回合开始时间点(roundStartTime相对于该值会有一个固定修正比例(延迟)battleRoundTimeFix)*/
	protected volatile long unFixRoundStartAt;
	/** 回合自动战斗下发时间点 */
	protected long curAutoNotifyTime;
	/** 回合手动战斗下发时间点 */
	protected long curManualNotifyTime;
	/** 回合预计播放时长(秒) */
	protected float curEstimatedPlayTimeSec;
	/** 是否已下发回合结果 */
	protected volatile boolean hasNotifyStart;
	/** 战斗开始时间 */
	protected long beginTime;
	/** 战斗结束时间（带客户端最后一回合播放动画时间,battleFinish时计算一次） */
	protected long endTime;
	/** 胜利队伍 */
	private BattleTeam winTeam;
	/** 失败队伍 */
	private BattleTeam loseTeam;
	/** 元数据记录 */
	private Map<String, Object> meta = new HashMap<>();

	private BattleFinishVo finishVo = new BattleFinishVo();
	/** 是否已通知客户端开始当前回合准备倒计时,roundStartTime时设置为true,在回合正式开始重置为false*/
	private boolean roundReadyNotify;
	
	public BattleAdapter() {
		id = IdUtils.generateLongId("BattleAdapter");
		this.battleInfo = createBattleInfo();
	}

	protected BattleInfo createBattleInfo() {
		return new DefaultBattleInfo();
	}

	@Override
	public int joinWatch(long playerId, final Set<Long> watchPlayerIds) {
		return this.battleInfo.joinWatch(playerId, watchPlayerIds);
	}

	@Override
	public void exitWatch(final Set<Long> watchPlayerIds, boolean notify) {
		this.battleInfo.exitWatch(watchPlayerIds);
		if (notify) {
			final GeckoMultiMessage message = new GeckoMultiMessage(new BattleWatchExit(getId()), watchPlayerIds);
			SceneModeService.getInstance().toOuter().send(message);
		}
	}

	@Override
	public long getId() {
		return id;
	}

	@Override
	public int getCount() {
		return count;
	}

	@Override
	public BattleInfo battleInfo() {
		return battleInfo;
	}

	@Override
	public void setBattleInfo(BattleInfo battleInfo) {
		this.battleInfo = battleInfo;
	}

	@Override
	public Video getVideo() {
		return video;
	}

	public void setVideo(Video video) {
		this.video = video;
	}

	public boolean isForceOver() {
		return forceOver;
	}

	public void setForceOver(boolean forceOver) {
		this.forceOver = forceOver;
	}

	/**
	 * 游戏准备时设置战斗到计时
	 */
	protected void ready() {
		long nowLong = System.currentTimeMillis();
		if (battleLog.isDebugEnabled())
			battleLog.debug(getId() + ".ready>>>roundStartTime:" + new Date(roundStartTime).toString() + ",nowLong:" + new Date(nowLong).toString());
		if (unFixRoundStartAt > nowLong)
			return;
		long curPlayTime = curEstimatedPlayTime();
		long fixMillis = count > 0 ? (long) (curPlayTime * battleRoundTimeFix()) : 0;
		this.unFixRoundStartAt = nowLong + curPlayTime - fixMillis;
		roundStartTime(nowLong + curPlayTime + fixMillis); // + millisPerSecond * ROUND_PLAY_TIME_FAULT_TOLERANT_SEC + curEstimatedPlayTime()
		hasNotifyStart = false;
		if (battleLog.isDebugEnabled())
			battleLog.debug(getId() + ".ready>>>curTime:" + new Date(nowLong).toString() + ",startTime:" + new Date(roundStartTime).toString() + ", curAutoNotifyTime:" + new Date(curAutoNotifyTime).toString() + ", curManualNotifyTime:" + new Date(curManualNotifyTime).toString());
	}

	public void roundStartTime(long startTime) {
		this.roundStartTime = startTime;
		this.curAutoNotifyTime = roundStartTime + DateUtils.MILLIS_PER_SECOND * battleRoundStartCancelAuoTime();
		this.curManualNotifyTime = roundStartTime + DateUtils.MILLIS_PER_SECOND * commandOpTime();
		if (battleLog.isDebugEnabled())
			battleLog.debug(getId() + ".roundStartTime>>>startTime:" + new Date(startTime).toString());
	}

	@Override
	public void checkStart() {
		if (this.unFixRoundStartAt == 0)
			return;
		long nowLong = System.currentTimeMillis();
		if (nowLong < this.unFixRoundStartAt || nowLong > this.curManualNotifyTime || this.isRoundRunning())
			throw new GeneralException(AppErrorCodes.BATTLE_OPTIME_EXPIRED);
	}

	@Override
	public boolean checkNotifyStart(long curTime) {
		if (isForceOver()) {
			return true;
		}
		//if (battleLog.isDebugEnabled())
		//battleLog.debug(getId() + ".checkNotifyStart>>>roundStartTime:" + new Date(this.roundStartTime).toString() + ",hasNotifyStart:" + hasNotifyStart + ", allReady:" + this.battleInfo().allReady());
		if (!roundStartable(curTime)) {
			return false;
		}
		checkRoundReady(curTime);
		checkAllAndSetAuto(curTime);
		if (battleInfo.isRoundStartable() || curTime >= this.curManualNotifyTime) {
			if (battleLog.isDebugEnabled())
				battleLog.debug(getId() + ".checkNotifyStart>>>curTime:" + new Date(curTime).toString() + ",startTime:" + new Date(roundStartTime).toString() + ", curManualNotifyTime:" + new Date(curManualNotifyTime).toString());
			hasNotifyStart = true;
			roundReadyNotify = false;//重置
			return hasNotifyStart;
		}
		return false;
	}

	private void checkRoundReady(long curTime) {
		if (!roundReadyNotify && this.count > 0) {
			roundReadyNotify = true;
			roundStartTime(curTime);//重设时间
			broadcast(new BattleRoundReadyNotify(this.count + 1));
		}
	}

	private void checkAllAndSetAuto(long curTime) {
		if (curTime >= this.curManualNotifyTime) {
			// 检查队伍中没有自动的人
			setTeamAutoBattle(battleInfo.getAteam());
			setTeamAutoBattle(battleInfo.getBteam());
		}
	}

	private void setTeamAutoBattle(BattleTeam team) {
		for (BattlePlayer bp : team.players()) {
			if (bp.isAutoBattle())
				continue;
			BattlePlayerSoldierInfo info = team.soldiersByPlayer(bp.getId());
			if (info != null) {
				BattleSoldier mainCharactor = team.soldier(info.mainCharactorSoldierId());
				if (mainCharactor != null && !mainCharactor.isAutoBattle() && mainCharactor.getCommandContext() == null) {
					if (needPlayerAutoBattle())
						bp.setAutoBattle(true);
					mainCharactor.setAutoBattle(true);
					BattleSoldier pet = team.soldier(info.petSoldierId());
					if (pet != null)
						pet.setAutoBattle(true);
				}
			}
		}
	}

	@Override
	public boolean needPlayerAutoBattle() {
		return true;
	}

	private boolean roundStartable(long curTime) {
		if (hasNotifyStart)
			return false;
		if (curTime < this.unFixRoundStartAt)
			return false;//最小时间都未到
		if (curTime >= this.roundStartTime || battleInfo.allReady()) {
			return true;//全部客户端准备就绪或者deadline时间到,回合开始
		}
		return false;
	}

	@Override
	public void roundStart() {
		onRoundStart();
		manual();
		try {
			broadcastVideoRound();
		} catch (Exception e) {
			e.printStackTrace();
		}
		this.battleRoundProcessor.clear();
		ready();
	}

	protected void onRoundStart() {
		this.battleInfo().clearRoundReadyPlayer();
	}

	protected void broadcastVideoRound() {
		VideoRound videoRound = this.video.getRounds().currentVideoRound();
		if (null == videoRound)
			return;
		if (battleLog.isDebugEnabled()) {
			String videoRoundString = JsonUtils.toString(videoRound);
			battleLog.debug(videoRoundString);
		}
		if (!videoRound.readyAction().getTargetStateGroups().isEmpty())
			this.addEstimatedPlaySec(0.5f);// 回合准备阶段+0.5播放时间(加减hp等动作)
		if (!videoRound.endAction().getTargetStateGroups().isEmpty())
			this.addEstimatedPlaySec(0.5f);// 回合结束阶段+0.5播放时间
		broadcast(videoRound);
	}

	protected void broadcastGameStartVideo(Video video) {
		if (null == video)
			return;
		video.setCommandOptSec(commandOpTime());
		video.setCancelAutoSec(battleRoundStartCancelAuoTime());
		broadcast(video);
		broadcastSceneInBattle(true);
		if (battleLog.isDebugEnabled()) {
			String videoString = "=========" + this.getId() + ":start video:[" + JsonUtils.toString(video) + "]";
			battleLog.debug(videoString);
		}
	}

	/**
	 * 下发场景是否在战斗
	 */
	@Override
	public void broadcastSceneInBattle(boolean inBattle) {
		long aTeamLeaderPlayerId = this.battleInfo().getAteam().leaderId();
		long bTeamLeaderPlayerId = this.battleInfo().getBteam().leaderId();
		final Set<Long> aTeamPlayerIds = this.battleInfo().getAteam().inBattlePlayerIds();
		final Set<Long> bTeamPlayerIds = this.battleInfo().getBteam().inBattlePlayerIds();

		BattlePlayer aTeamLeaderPlayer = this.battleInfo().aTeamPlayers().get(aTeamLeaderPlayerId);
		BattlePlayer bTeamLeaderPlayer = this.battleInfo().bTeamPlayers().get(bTeamLeaderPlayerId);

		if (null == aTeamLeaderPlayer && null == bTeamLeaderPlayer)
			return;

		int aTeamSceneId = 0;
		if (null != aTeamLeaderPlayer)
			aTeamSceneId = aTeamLeaderPlayer.getSceneId();

		int bTeamSceneId = 0;
		if (null != bTeamLeaderPlayer)
			bTeamSceneId = bTeamLeaderPlayer.getSceneId();

		SceneManager sceneManager = SceneManager.getInstance();
		if (aTeamSceneId != bTeamSceneId) {
			Scene aTeamScene = sceneManager.getScene(aTeamSceneId);
			if (null != aTeamScene && aTeamPlayerIds.size() > 0) {
				// aTeamScene.screenBroadcast(aTeamLeaderPlayer, new BattleSceneNotify(inBattle, aTeamPlayerIds));
				aTeamScene.screenBroadcast(aTeamLeaderPlayer.getId(), new BattleSceneNotify(inBattle, aTeamPlayerIds));
			}

			Scene bTeamScene = sceneManager.getScene(bTeamSceneId);
			if (null != bTeamScene && bTeamPlayerIds.size() > 0) {
				// bTeamScene.screenBroadcast(bTeamLeaderPlayer, new BattleSceneNotify(inBattle, bTeamPlayerIds));
				bTeamScene.screenBroadcast(bTeamLeaderPlayer.getId(), new BattleSceneNotify(inBattle, bTeamPlayerIds));
			}
		} else {
			Scene scene = sceneManager.getScene(aTeamSceneId);
			if (scene != null) {
				aTeamPlayerIds.addAll(bTeamPlayerIds);
				if (!aTeamPlayerIds.isEmpty()) {
					BattleSceneNotify notify = new BattleSceneNotify(inBattle, aTeamPlayerIds);
					if (aTeamLeaderPlayer != null)
						scene.screenBroadcast(aTeamLeaderPlayer.getId(), notify);
					if (bTeamLeaderPlayer != null)
						scene.screenBroadcast(bTeamLeaderPlayer.getId(), notify);
				}
			}
		}
	}

	@Override
	public void broadcast(TerminalMessage message, Long... excludePlayerIds) {
		BattleTeam ateam = battleInfo.getAteam();
		BattleTeam bteam = battleInfo.getBteam();

		Set<Long> playerIdsSet = new HashSet<Long>();
		playerIdsSet.addAll(ateam.onlineTeamPlayerIds());
		playerIdsSet.addAll(bteam.onlineTeamPlayerIds());
		playerIdsSet.addAll(battleInfo.watchList());
		if (this.battleRoundProcessor != null) {
			if (!this.battleRoundProcessor.retreatPlayerId().isEmpty()) {
				playerIdsSet.addAll(this.battleRoundProcessor.retreatPlayerId());
				// 这里移除撤退玩家是避免已经撤退的玩家再次收到通知
				this.battleRoundProcessor.retreatPlayerId().clear();
			}
		}
		if (excludePlayerIds != null) {
			for (long id : excludePlayerIds)
				playerIdsSet.remove(id);
		}
		// 战斗相关的人都在线才发战斗信息,否则如果playerIdsSet为空的话会发给整个场景无关的人
		if (!playerIdsSet.isEmpty()) {
			SceneModeService.getInstance().toOuter().send(new GeckoMultiMessage(message, playerIdsSet));
		}
	}

	public final void start() {
		initBattleInfo();
		afterInitBattleInfo();
		initVideo();
		BattleManager.getInstance().ready(this);
		ready();
		this.beforeStart();
		broadcastGameStartVideo(getVideo());
		this.beginTime = System.currentTimeMillis();
		this.afterStart();
	}

	protected void beforeStart() {
		final List<BattleSoldier> allSoldiers = new ArrayList<>(battleInfo().getAteam().allSoldiersMap().values());
		allSoldiers.addAll(battleInfo().getBteam().allSoldiersMap().values());
		for(BattleSoldier soldier : allSoldiers) {
			soldier.beforeStart();
		}
	}

	protected void afterStart() {
		checkAuto(this.battleInfo.getAteam());
		checkAuto(this.battleInfo.getBteam());
	}

	private void checkAuto(BattleTeam team) {
		for (BattlePlayer bp : team.players()) {
			if (!bp.isConnected() || (needPlayerAutoBattle() && bp.isAutoBattle())) {// 离线
				BattlePlayerSoldierInfo info = team.soldiersByPlayer(bp.getId());
				if (info != null) {
					BattleSoldier mainCharactor = team.soldier(info.mainCharactorSoldierId());
					if (mainCharactor != null)
						mainCharactor.setAutoBattle(true);
					BattleSoldier pet = team.soldier(info.petSoldierId());
					if (pet != null)
						pet.setAutoBattle(true);
				}
			}
		}
	}

	protected final void initAutoBattle() {
		initBattleInfo();
		afterInitBattleInfo();
		initVideo();
		BattleManager.getInstance().ready(this);
		auto();
	}

	protected void afterInitBattleInfo() {
		BattleTeam ateam = this.battleInfo.getAteam();
		BattleTeam bteam = this.battleInfo.getBteam();
		ateam.setEnemyTeam(bteam);
		bteam.setEnemyTeam(ateam);
		passiveSkillEffect();
	}

	/**
	 * 重设属性(怪物才需要)
	 * 
	 * @param team
	 */
	protected void initTeamSoldiersProperty(BattleTeam team) {
		for (Iterator<BattleSoldier> it = team.soldiersMap().values().iterator(); it.hasNext();) {
			BattleSoldier soldier = it.next();
			if (soldier.battleUnit() instanceof Monster) {
				Monster monster = (Monster) soldier.battleUnit();
				soldier.setGrade(monster.level(team.getEnemyTeam()));// 怪物能力等级根据对方(玩家方)而定
				soldier.setSpellLevel(monster.spellLevel(team.getEnemyTeam()));// 修炼等级
				soldier.initProperties();
			}
		}
	}

	protected void manual() {
		count();
		roundProcess();
		if (isOver(true)) {
			over();
		}
	}

	protected void auto() {
		while (!isOver(true)) {
			count();
			roundProcess();
		}
		over();
	}

	protected final void count() {
		count++;
	}

	protected final void roundProcess() {
		battleRoundProcessor().handle();
	}

	@Override
	public BattleRoundProcessor battleRoundProcessor() {
		if (battleRoundProcessor == null)
			battleRoundProcessor = createBattleRoundProcessor();
		return battleRoundProcessor;
	}

	protected BattleRoundProcessor createBattleRoundProcessor() {
		return new DefaultBattleRoundProcessor(this);
	}

	/** 战斗结束 */
	protected final void over() {
		VideoRound lastVideoRound = this.video.getRounds().currentVideoRound();
		if (null == lastVideoRound)
			return;
		lastVideoRound.over(this);
		try {
			battleFinish(winTeam, loseTeam);
			afterBattleFinish();
			SceneManager.getInstance().forward(AppServerMode.Core, finishVo());
		} catch (Exception ex) {
			ex.printStackTrace();
			errorLog.error("battle over error at" + battleInfo(), ex);
		}
		discard();
	}

	protected void afterBattleFinish() {
		battleFinishCallback();
	}

	private void battleFinishCallback() {
		for (BattlePlayer bp : this.battleInfo.aTeamPlayers().values()) {
			BattleSoldier s = this.battleInfo.getAteam().allSoldiersMap().get(bp.getId());
			if (s != null) {
				s.battleFinishCallbackHandle();
			}
		}
		for (BattlePlayer bp : this.battleInfo.bTeamPlayers().values()) {
			BattleSoldier s = this.battleInfo.getBteam().allSoldiersMap().get(bp.getId());
			if (s != null)
				s.battleFinishCallbackHandle();
		}
	}

	@Override
	public boolean isOver(boolean currentRoundAsMaxCheck) {
		if (isForceOver())
			return true;
		BattleInfo battleInfo = battleInfo();
		if (isDraw(currentRoundAsMaxCheck))
			return true;
		if (battleInfo.getAteam().isAllDead()) {
			winTeam = battleInfo.getBteam();
			loseTeam = battleInfo.getAteam();
			getVideo().setWinId(winTeam.leaderId());
			return true;
		}
		if (battleInfo.getBteam().isAllDead()) {
			winTeam = battleInfo.getAteam();
			loseTeam = battleInfo.getBteam();
			getVideo().setWinId(winTeam.leaderId());
			return true;
		}
		return false;
	}

	@Override
	public boolean isRoundOver() {
		if (this.battleInfo().getAteam().isAllDead())
			return true;
		if (this.battleInfo().getBteam().isAllDead())
			return true;
		return false;
	}

	protected int maxRound() {
		return StaticConfig.get(AppStaticConfigs.DEFAULT_MAX_ROUND).getAsInt(99);
	}

	protected boolean isDraw(boolean currentRoundAsMaxCheck) {
		if (currentRoundAsMaxCheck ? this.getCount() >= maxRound() : this.getCount() > maxRound())
			return true;
		BattleInfo gameInfo = battleInfo();
		if (gameInfo.getAteam().isAllDead() && gameInfo.getBteam().isAllDead())
			return true;
		return false;
	}

	private void discard() {
		BattleManager.getInstance().over(this);
	}

	/** 战斗创建 */
	protected void initBattleInfo() {
		this.battleInfo.setAteam(initAteam());
		this.battleInfo.setBteam(initBteam());
	}

	private void passiveSkillEffect() {
		for (BattleSoldier soldier : this.battleInfo.getAteam().soldiersMap().values()) {
			soldier.skillHolder().passiveSkillEffectByTiming(soldier, null, PassiveSkillLaunchTimingEnum.BattleReady);
		}
		for (BattleSoldier soldier : this.battleInfo.getBteam().soldiersMap().values()) {
			soldier.skillHolder().passiveSkillEffectByTiming(soldier, null, PassiveSkillLaunchTimingEnum.BattleReady);
		}

	}

	protected BattleTeam initAteam() {
		return new BattleTeam(this.battleInfo.aTeamPlayers().values(), this);
	}

	protected abstract BattleTeam initBteam();

	protected abstract Video createVideo();

	protected void initVideo() {
		Video video = createVideo();
		video.setId(this.getId());
		video.setNeedPlayerAutoBattle(this.needPlayerAutoBattle());
		video.setRetreatable(this.retreatable());

		BattleInfo battleInfo = battleInfo();
		video.setAteam(battleInfo.getAteam().toVideoTeam());
		video.setBteam(battleInfo.getBteam().toVideoTeam());
		this.setVideo(video);

		battleInfo.getAteam().setVideoTeam(video.getAteam());
		battleInfo.getBteam().setVideoTeam(video.getBteam());
		initPetsOfPlayer();
	}

	@Override
	public void initPetsOfPlayer() {
		List<BattlePlayerSoldierInfo> playerSoldierInfos = new ArrayList<BattlePlayerSoldierInfo>();
		playerSoldierInfos.addAll(battleInfo.getAteam().playerSoldierInfos());
		playerSoldierInfos.addAll(battleInfo.getBteam().playerSoldierInfos());
		List<BattlePlayerInfoDto> playerInfos = new ArrayList<BattlePlayerInfoDto>();
		for (Iterator<BattlePlayerSoldierInfo> it = playerSoldierInfos.iterator(); it.hasNext();) {
			BattlePlayerSoldierInfo info = it.next();
			playerInfos.add(new BattlePlayerInfoDto(info));
		}
		video.setPlayerInfos(playerInfos);
	}

	@Override
	public long curAutoNotifyTime() {
		return curAutoNotifyTime;
	}

	@Override
	public long curManualNotifyTime() {
		return curManualNotifyTime;
	}

	@Override
	public long curEstimatedPlayTime() {
		return Math.round(DateUtils.MILLIS_PER_SECOND * curEstimatedPlayTimeSec);
	}

	@Override
	public void resetEstimatedPlayTime() {
		this.curEstimatedPlayTimeSec = 0F;
	}

	@Override
	public void addEstimatedPlaySec(float seconds) {
		if (seconds <= 0)
			return;
		this.curEstimatedPlayTimeSec += seconds;
	}

	/** 新增战斗成员 */
	@Override
	public List<BattleSoldier> newJoinBattleSoldiers() {
		List<BattleSoldier> newJoinBattleSoldiers = new ArrayList<BattleSoldier>();
		newJoinBattleSoldiers.addAll(battleInfo.getAteam().nextRoundNewJoinSoldiers());
		battleInfo.getAteam().clearNextRoundNewJoinSoldiers();
		newJoinBattleSoldiers.addAll(battleInfo.getBteam().nextRoundNewJoinSoldiers());
		battleInfo.getBteam().clearNextRoundNewJoinSoldiers();
		return newJoinBattleSoldiers;
	}

	/** 替换成员 */
	@Override
	public List<Long> substitudeSoldierIds() {
		List<Long> substitudeSoldierIds = new ArrayList<Long>();
		substitudeSoldierIds.addAll(battleInfo.getAteam().nextRoundSubstitudeSoldierIds());
		battleInfo.getAteam().clearNextRoundSubstitudeSoldierIds();
		substitudeSoldierIds.addAll(battleInfo.getBteam().nextRoundSubstitudeSoldierIds());
		battleInfo.getBteam().clearNextRoundSubstitudeSoldierIds();
		return substitudeSoldierIds;
	}

	@Override
	public void clear() {

	}

	@Override
	public void addRetreatPlayerId(long playerId) {
		this.battleRoundProcessor.retreatPlayerId().add(playerId);
	}

	@Override
	public boolean isRoundRunning() {
		return hasNotifyStart;
	}

	/**
	 * 战斗队伍列表
	 * 
	 * @param teamLeader
	 * @return
	 */
	protected void initTeamPlayers(BattlePlayer teamLeader, Map<Long, BattlePlayer> players) {
		players.put(teamLeader.getId(), teamLeader);
		if (!teamLeader.ifTeamLeader())
			return;
		final List<BattlePlayer> teamPlayers = teamLeader.teamBattlePlayers();
		for (BattlePlayer teamPlayer : teamPlayers) {
			if (teamPlayer.getId() == teamLeader.getId()) {
				continue;
			}
			players.put(teamPlayer.getId(), teamPlayer);
		}
	}

	/** 战斗完成 */
	protected void battleFinish(BattleTeam winTeam, BattleTeam loseTeam) {
		long battleEndAt = getBattleEndTime();
		for (BattlePlayer bp : this.battleInfo.getAteam().players()) {
			bp.battleEndAt(battleEndAt);
		}
		for (BattlePlayer bp : this.battleInfo.getBteam().players()) {
			bp.battleEndAt(battleEndAt);
		}
		finishVo().onFinish(this, winTeam, loseTeam);
	}

	public BattleFinishVo finishVo() {
		return finishVo;
	}

	@Override
	public long getBattleEndTime() {
		if (this.endTime <= 0L) {
			endTime = System.currentTimeMillis() + this.curEstimatedPlayTime();
		}
		return endTime;
	}

	@Override
	public void capturePet(CommandContext commandContext) {
		// override at subclass
	}

	public BattleRoundProcessor getBattleRoundProcessor() {
		return battleRoundProcessor;
	}

	public void setBattleRoundProcessor(BattleRoundProcessor battleRoundProcessor) {
		this.battleRoundProcessor = battleRoundProcessor;
	}

	@Override
	public Collection<Long> allPlayerIds() {
		List<Long> playerIds = new ArrayList<Long>();
		playerIds.addAll(battleInfo.getAteam().playerIds());
		playerIds.addAll(battleInfo.getBteam().playerIds());
		return playerIds;
	}

	protected void loseDuration(BattleTeam battleTeam) {
		if (battleTeam == null)
			return;
		List<Long> playerList = new ArrayList<Long>(battleTeam.playerIds());
		playerList.addAll(battleTeam.retreatPlayerIds());
		if (playerList.isEmpty())
			return;
		// final int deductPoint = StaticConfig.get(H1StaticConfigs.EQUIPMENT_DURATION_DEDUCT_POINT).getAsInt(50);

		for (BattlePlayer player : battleTeam.players()) {
			BattleSoldier battleSoldier = battleTeam.allSoldiersMap().get(player.getId());
			if (battleSoldier == null)
				continue;
			int attackTimes = battleSoldier.getAttackTimes();
			int beAttackTimes = battleSoldier.getBeAttackTimes();
			boolean dead = battleSoldier.isDead();
			if (attackTimes <= 0 && beAttackTimes <= 0 && !dead)
				continue;
			// player.dispatchEvent(BattleEvent.wrap(new LoseDurationEvent(attackTimes, beAttackTimes, dead)));
			finishVo().addEvent(BattleEvent.wrap(player.getId(), new LoseDurationEvent(attackTimes, beAttackTimes, dead)));
		}
	}

	@Override
	public void populateDefaultSkill(BattlePlayer player, int mainCharactorDefaultBattleSkillId, int petDefaultBattleSkillId) {
		BattleTeam team = this.battleInfo.myTeam(player.getId());
		BattlePlayerSoldierInfo info = team.soldiersByPlayer(player.getId());
		if (info != null) {
			BattleSoldier mainCharactor = team.battleSoldier(info.mainCharactorSoldierId());
			if (mainCharactor != null) {
				mainCharactor.battleUnit().defaultSkillId(mainCharactorDefaultBattleSkillId);
			}
			if (info.petSoldierId() > 0) {
				BattleSoldier pet = team.battleSoldier(info.petSoldierId());
				if (pet != null) {
					pet.battleUnit().defaultSkillId(petDefaultBattleSkillId);
				}
			}
		}
	}

	public void forceOver(long playerId) {
		this.loseTeam = this.battleInfo.myTeam(playerId);
		this.winTeam = this.battleInfo().enemyTeam(playerId);
		getVideo().setWinId(winTeam.leaderId());
		setForceOver(true);
	}

	@Override
	public void manualRoundReady(long playerId) {
		this.battleInfo().addRoundReadyPlayer(playerId);
		checkAutoReady();
	}
	/**
	 * 如果有玩家离线,则帮他自动设置就绪
	 */
	private void checkAutoReady() {
		Predicate<BattlePlayer> predicate = p -> !p.isConnected() && !battleInfo.roundReadyPlayers().contains(p.getId());
		Consumer<BattlePlayer> consumer = p -> battleInfo.addRoundReadyPlayer(p.getId());
		battleInfo.getAteam().players().stream().filter(predicate).forEach(consumer);
		battleInfo.getBteam().players().stream().filter(predicate).forEach(consumer);
	}

	public void putAllMeta(Map<String, Object> meta) {
		this.meta.putAll(meta);
	}

	public Map<String, Object> metaMap() {
		return this.meta;
	}

	public Object getMeta(String key) {
		return this.meta.get(key);
	}

	public void putMeta(String key, Object value) {
		this.meta.put(key, value);
	}

	@Override
	public long beginTime() {
		return this.beginTime;
	}

	public VideoRound currentVideoRound() {
		return this.video.getRounds().currentVideoRound();
	}

	@Override
	public int mpSpent(CommandContext context, BattleSoldier trigger, int mpSpent) {
		return mpSpent;
	}

	@Override
	public void onBuffAdd(CommandContext context, BattleSoldier trigger, BattleSoldier target, List<BattleBuffEntity> addBuffs) {

	}
	
	@Override
	public boolean retreatable() {
		return true;
	}
}
