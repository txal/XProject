package com.nucleus.logic.core.modules.battle.dto;

/**
 * 战斗录像
 * 
 * @author wgy
 *
 */
public class VideoRecord extends Video {
	/** 战斗回合记录器 */
	private VideoRounds rounds;

	public VideoRecord() {
	}

	public VideoRecord(Video video) {
		this.setAteam(video.getAteam());
		this.setBteam(video.getBteam());
		this.setCameraId(video.getCameraId());
		this.setCancelAutoSec(video.getCancelAutoSec());
		this.setCommandOptSec(video.getCommandOptSec());
		this.setCurrentRound(video.getCurrentRound());
		this.setCurrentRoundCommandOptRemainSec(video.getCurrentRoundCommandOptRemainSec());
		this.setId(video.getId());
		this.setMapId(video.getMapId());
		this.setMaxRound(video.getMaxRound());
		this.setPlayerInfos(video.getPlayerInfos());
		this.setRounds(video.getRounds());
		this.setWinId(video.getWinId());
	}

	public VideoRounds getRounds() {
		return rounds;
	}

	public void setRounds(VideoRounds rounds) {
		this.rounds = rounds;
	}
}
