package com.nucleus.logic.core.modules.battle.dto;

import java.util.ArrayList;
import java.util.List;

import com.nucleus.commons.message.BroadcastMessage;
import com.nucleus.commons.message.GeneralResponse;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;

public class DebugVideoRound extends GeneralResponse implements BroadcastMessage {
	/**
	 * 当前回合数
	 */
	private int round;
	/**
	 * 准备状态信息
	 */
	private List<String> readyInfo = new ArrayList<String>();
	/**
	 * 战斗进程信息
	 */
	private List<String> progressInfo = new ArrayList<String>();

	public DebugVideoRound() {
	}

	public DebugVideoRound(int round) {
		this.round = round;
	}

	public void addReadyInfo(String info) {
		this.readyInfo.add(info);
	}

	public void addReadyInfo(BattleSoldier soldier) {
		this.addReadyInfo(soldier.toBattleInfo());
	}

	public void addReadyInfos(List<BattleSoldier> soldiers) {
		for (BattleSoldier soldier : soldiers)
			this.addReadyInfo(soldier);
	}

	public void info(String msg) {
		this.progressInfo.add(msg);
	}

	public int getRound() {
		return round;
	}

	public void setRound(int round) {
		this.round = round;
	}

	public List<String> getReadyInfo() {
		return readyInfo;
	}

	public void setReadyInfo(List<String> readyInfo) {
		this.readyInfo = readyInfo;
	}

	public List<String> getProgressInfo() {
		return progressInfo;
	}

	public void setProgressInfo(List<String> progressInfo) {
		this.progressInfo = progressInfo;
	}

	public void clear() {
		readyInfo.clear();
		progressInfo.clear();
	}
}
