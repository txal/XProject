/**
 * 
 */
package com.nucleus.logic.core.modules.battle.dto;

import java.util.ArrayList;
import java.util.List;

import javax.persistence.Transient;

import org.apache.commons.lang3.builder.ReflectionToStringBuilder;
import org.apache.commons.lang3.builder.ToStringStyle;

import com.nucleus.commons.message.GeneralResponse;

/**
 * @author Omanhom
 * 
 */
public abstract class Video extends GeneralResponse {
	public Video() {
	}

	public Video(int maxRound) {
		this.rounds = new VideoRounds();
		this.maxRound = maxRound;
	}

	/** 游戏编号 */
	private long id;
	/** 回合可操作时长(秒) */
	private int commandOptSec;
	/** 回合可取消自动战斗时长 */
	private int cancelAutoSec;
	/** 当前回合剩余操作时间(仅限战斗中重新登录使用) */
	private int currentRoundCommandOptRemainSec;
	/** 胜利编号 */
	private long winId;
	/** 战斗地图编号 */
	private int mapId;
	/** 战斗镜头编号 */
	private int cameraId;
	/** a队 */
	private VideoTeam ateam;
	/** b队 */
	private VideoTeam bteam;
	/** 战斗回合记录器 */
	private VideoRounds rounds;
	/** 最大回合数 */
	private int maxRound;
	/** 当前回合 */
	private int currentRound;
	/** 参战玩家信息 */
	private List<BattlePlayerInfoDto> playerInfos;
	/** 玩家自动战斗标记 */
	private boolean needPlayerAutoBattle;
	/** 战斗开始状态 */
	private List<VideoTargetState> startStates;
	/** 是否可撤退*/
	private boolean retreatable;
	public VideoTeam teamByPlayer(long playerId) {
		VideoTeam team = null;
		if (ateam.hasPlayer(playerId)) {
			team = ateam;
		} else if (bteam.hasPlayer(playerId)) {
			team = bteam;
		}
		return team;
	}

	public long getWinId() {
		return winId;
	}

	public void setWinId(long winId) {
		this.winId = winId;
	}

	public int getMapId() {
		return mapId;
	}

	public void setMapId(int mapId) {
		this.mapId = mapId;
	}

	public int getCameraId() {
		return cameraId;
	}

	public void setCameraId(int cameraId) {
		this.cameraId = cameraId;
	}

	public VideoTeam getAteam() {
		return ateam;
	}

	public void setAteam(VideoTeam ateam) {
		this.ateam = ateam;
	}

	public VideoTeam getBteam() {
		return bteam;
	}

	public void setBteam(VideoTeam bteam) {
		this.bteam = bteam;
	}

	public VideoRounds getRounds() {
		return rounds;
	}

	@Transient
	public void setRounds(VideoRounds rounds) {
		this.rounds = rounds;
	}

	public int getCommandOptSec() {
		return commandOptSec;
	}

	public void setCommandOptSec(int commandOptSec) {
		this.commandOptSec = commandOptSec;
	}

	public int getCancelAutoSec() {
		return cancelAutoSec;
	}

	public void setCancelAutoSec(int cancelAutoSec) {
		this.cancelAutoSec = cancelAutoSec;
	}

	@Override
	public String toString() {
		return ReflectionToStringBuilder.toString(this, ToStringStyle.SHORT_PREFIX_STYLE);
	}

	public int getMaxRound() {
		return maxRound;
	}

	public void setMaxRound(int maxRound) {
		this.maxRound = maxRound;
	}

	public long getId() {
		return id;
	}

	public void setId(long id) {
		this.id = id;
	}

	public int getCurrentRound() {
		return currentRound;
	}

	public void setCurrentRound(int currentRound) {
		this.currentRound = currentRound;
	}

	public List<BattlePlayerInfoDto> getPlayerInfos() {
		return playerInfos;
	}

	public void setPlayerInfos(List<BattlePlayerInfoDto> playerInfos) {
		this.playerInfos = playerInfos;
	}

	public int getCurrentRoundCommandOptRemainSec() {
		return currentRoundCommandOptRemainSec;
	}

	public void setCurrentRoundCommandOptRemainSec(int currentRoundCommandOptRemainSec) {
		this.currentRoundCommandOptRemainSec = currentRoundCommandOptRemainSec;
	}

	public void restore() {
		this.ateam.restore();
		this.bteam.restore();
	}

	public boolean isNeedPlayerAutoBattle() {
		return needPlayerAutoBattle;
	}

	public void setNeedPlayerAutoBattle(boolean needPlayerAutoBattle) {
		this.needPlayerAutoBattle = needPlayerAutoBattle;
	}

	public List<VideoTargetState> getStartStates() {
		return startStates;
	}

	public void setStartStates(List<VideoTargetState> startStates) {
		this.startStates = startStates;
	}

	public void addStartState(VideoTargetState state) {
		if(startStates == null)
			startStates = new ArrayList<>();
		startStates.add(state);
	}

	public boolean isRetreatable() {
		return retreatable;
	}

	public void setRetreatable(boolean retreatable) {
		this.retreatable = retreatable;
	}
}
