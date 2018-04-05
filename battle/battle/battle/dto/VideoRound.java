/**
 * 
 */
package com.nucleus.logic.core.modules.battle.dto;

import java.beans.Transient;
import java.util.ArrayList;
import java.util.List;

import org.apache.commons.lang3.builder.ReflectionToStringBuilder;
import org.apache.commons.lang3.builder.ToStringStyle;

import com.nucleus.commons.message.BroadcastMessage;
import com.nucleus.commons.message.GeneralResponse;
import com.nucleus.logic.core.modules.battle.model.Battle;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;

/**
 * @author liguo
 * 
 */
public class VideoRound extends GeneralResponse implements BroadcastMessage {
	/** 战斗id */
	private long battleId;
	/** 当前回合数 */
	private int count;
	/** 游戏是否结束 */
	private boolean over;
	/** 胜利玩家编号，0表示怪物，null表平局 */
	private long winId;
	/** 回合准备 */
	private VideoRoundAction readyAction = new VideoRoundAction();
	/** 当前回合过程所有的动作,元素为VideoSkillAction子类 */
	private List<VideoSkillAction> skillActions;
	/** 回合结束 */
	private VideoRoundAction endAction = new VideoRoundAction();
	/** 回合结束后一些附加动作 */
	private VideoRoundAction afterEndAction = new VideoRoundAction();
	/** 新增成员 */
	private List<VideoSoldier> newJoinSoldiers = new ArrayList<VideoSoldier>();
	/** 新增成员被替换士兵编号 */
	private List<Long> substitudeSoldierIds;
	/** 喊话状态 */
	private List<VideoTargetShoutState> shoutStates;

	/**
	 * 调试信息
	 */
	private DebugVideoRound debugInfo;

	public VideoRound() {
	}

	public VideoRound(Battle battle) {
		this.battleId = battle.getId();
		this.count = battle.getCount();
		skillActions = new ArrayList<VideoSkillAction>();
		List<BattleSoldier> newJoinBattleSoldiers = battle.newJoinBattleSoldiers();
		for (int i = 0; i < newJoinBattleSoldiers.size(); i++) {
			newJoinSoldiers.add(new VideoSoldier(newJoinBattleSoldiers.get(i)));
		}
		this.setSubstitudeSoldierIds(battle.substitudeSoldierIds());
	}

	public long getBattleId() {
		return battleId;
	}

	public void setBattleId(long battleId) {
		this.battleId = battleId;
	}

	public int getCount() {
		return count;
	}

	public void setCount(int count) {
		this.count = count;
	}

	public boolean isOver() {
		return over;
	}

	public void setOver(boolean over) {
		this.over = over;
	}

	public long getWinId() {
		return winId;
	}

	public void setWinId(long winId) {
		this.winId = winId;
	}

	public List<VideoSkillAction> getSkillActions() {
		return skillActions;
	}

	public void setSkillActions(List<VideoSkillAction> skillActions) {
		this.skillActions = skillActions;
	}

	public VideoRoundAction getReadyAction() {
		return readyAction;
	}

	public void setReadyAction(VideoRoundAction readyAction) {
		this.readyAction = readyAction;
	}

	public VideoRoundAction getEndAction() {
		return endAction;
	}

	public void setEndAction(VideoRoundAction endAction) {
		this.endAction = endAction;
	}

	public VideoRoundAction endAction() {
		return this.endAction;
	}

	public VideoRoundAction readyAction() {
		return this.readyAction;
	}

	public void addSkillAction(VideoSkillAction action) {
		if (null == action) {
			return;
		}
		this.skillActions.add(action);
	}

	public void addNewJoinPlayer(BattleSoldier battleSoldier, long substitudeSoldierId) {
		this.getNewJoinSoldiers().add(new VideoSoldier(battleSoldier));
		this.getSubstitudeSoldierIds().add(substitudeSoldierId);
	}

	public void over(Battle battle) {
		this.over = true;
		this.winId = battle.getVideo().getWinId();
	}

	@Override
	public String toString() {
		return ReflectionToStringBuilder.toString(this, ToStringStyle.SHORT_PREFIX_STYLE);
	}

	@Override
	public int hashCode() {
		final int prime = 31;
		int result = 1;
		result = prime * result + count;
		result = prime * result + ((skillActions == null) ? 0 : skillActions.hashCode());
		return result;
	}

	@Override
	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;
		VideoRound other = (VideoRound) obj;
		if (count != other.count)
			return false;
		if (skillActions == null) {
			if (other.skillActions != null)
				return false;
		} else if (!skillActions.equals(other.skillActions))
			return false;
		return true;
	}

	public List<VideoSoldier> getNewJoinSoldiers() {
		return newJoinSoldiers;
	}

	@Transient
	public void setNewJoinSoldiers(List<VideoSoldier> newJoinSoldiers) {
		this.newJoinSoldiers = newJoinSoldiers;
	}

	public List<Long> getSubstitudeSoldierIds() {
		return substitudeSoldierIds;
	}

	@Transient
	public void setSubstitudeSoldierIds(List<Long> substitudeSoldierIds) {
		this.substitudeSoldierIds = substitudeSoldierIds;
	}

	public DebugVideoRound getDebugInfo() {
		return debugInfo;
	}

	public void setDebugInfo(DebugVideoRound debugInfo) {
		this.debugInfo = debugInfo;
	}

	public VideoRoundAction afterEndAction() {
		return this.afterEndAction;
	}

	public VideoRoundAction getAfterEndAction() {
		return afterEndAction;
	}

	public void setAfterEndAction(VideoRoundAction afterEndAction) {
		this.afterEndAction = afterEndAction;
	}

	public List<VideoTargetShoutState> getShoutStates() {
		return shoutStates;
	}

	public void setShoutStates(List<VideoTargetShoutState> shoutStates) {
		this.shoutStates = shoutStates;
	}

	public void addShoutState(VideoTargetShoutState shoutState) {
		if(shoutStates == null)
			shoutStates = new ArrayList<>();
		shoutStates.add(shoutState);
	}
}
