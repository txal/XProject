/**
 * 
 */
package com.nucleus.logic.core.modules.battle.dto;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import org.apache.commons.lang3.builder.ReflectionToStringBuilder;
import org.apache.commons.lang3.builder.ToStringStyle;

import com.nucleus.commons.data.DataId;
import com.nucleus.logic.core.modules.battle.data.Skill;

/**
 * @author liguo
 * 
 */
public class VideoSkillAction extends VideoAction {

	/** 行动开始动作 */
	private List<VideoInsideSkillAction> beforeActions = new ArrayList<VideoInsideSkillAction>();

	/** 行动结束动作 */
	private List<VideoInsideSkillAction> afterActions = new ArrayList<VideoInsideSkillAction>();

	/** 保护动作 */
	private List<VideoInsideSkillAction> protectActions = new ArrayList<VideoInsideSkillAction>();

	/** 保护对方士兵编号列表 */
	private List<Long> protectTargetSoldierIds = new ArrayList<Long>();

	/** 对方是战斗状态状态 */
	private int targetSoldierStatus;

	/** 反击 */
	private VideoSkillAction strikeBackSkillAction;

	/** 技能触发者 */
	private long actionSoldierId;

	/** 消耗hp值 */
	private int hpSpent;

	/** 消耗mp值 */
	private int mpSpent;
	/** 消耗怒气 */
	private int spSpent;
	/** 技能状态信息(StaticString) */
	private int skillStatusCode;
	/** 消耗法宝法力 */
	private int magicManaSpent;

	/** 施放技能编号 */
	@DataId(Skill.class)
	private int skillId;
	/** 被动技能编号 */
	private Set<Integer> passiveSkillId = new HashSet<>();

	public VideoSkillAction() {
	}

	public VideoSkillAction(long actionSoldierId) {
		this.setActionSoldierId(actionSoldierId);
	}

	public void addBeforeAction(VideoInsideSkillAction beforeAction) {
		beforeActions.add(beforeAction);
	}

	public void addAfterAction(VideoInsideSkillAction afterAction) {
		getAfterActions().add(afterAction);
	}

	public long getActionSoldierId() {
		return actionSoldierId;
	}

	public void setActionSoldierId(long actionSoldierId) {
		this.actionSoldierId = actionSoldierId;
	}

	public int getSkillId() {
		return skillId;
	}

	public void setSkillId(int skillId) {
		this.skillId = skillId;
	}

	@Override
	public String toString() {
		return ReflectionToStringBuilder.toString(this, ToStringStyle.SHORT_PREFIX_STYLE);
	}

	@Override
	public int hashCode() {
		final int prime = 31;
		int result = super.hashCode();
		result = (int) (prime * result + actionSoldierId);
		result = prime * result + skillId;
		return result;
	}

	@Override
	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (!super.equals(obj))
			return false;
		if (getClass() != obj.getClass())
			return false;
		VideoSkillAction other = (VideoSkillAction) obj;
		if (actionSoldierId <= 0) {
			if (other.actionSoldierId > 0)
				return false;
		} else if (actionSoldierId == other.actionSoldierId)
			return false;
		if (skillId != other.skillId)
			return false;
		return true;
	}

	public int getSkillStatusCode() {
		return skillStatusCode;
	}

	public void setSkillStatusCode(int skillStatusCode) {
		this.skillStatusCode = skillStatusCode;
	}

	public int getHpSpent() {
		return hpSpent;
	}

	public void setHpSpent(int hpSpent) {
		this.hpSpent = hpSpent;
	}

	public int getMpSpent() {
		return mpSpent;
	}

	public void setMpSpent(int mpSpent) {
		this.mpSpent = mpSpent;
	}

	public List<VideoInsideSkillAction> getBeforeActions() {
		return beforeActions;
	}

	public void setBeforeActions(List<VideoInsideSkillAction> beforeActions) {
		this.beforeActions = beforeActions;
	}

	public List<VideoInsideSkillAction> getAfterActions() {
		return afterActions;
	}

	public void setAfterActions(List<VideoInsideSkillAction> afterActions) {
		this.afterActions = afterActions;
	}

	public VideoSkillAction getStrikeBackSkillAction() {
		return strikeBackSkillAction;
	}

	public void setStrikeBackSkillAction(VideoSkillAction strikeBackSkillAction) {
		this.strikeBackSkillAction = strikeBackSkillAction;
	}

	public int getTargetSoldierStatus() {
		return targetSoldierStatus;
	}

	public void setTargetSoldierStatus(int targetSoldierStatus) {
		this.targetSoldierStatus = targetSoldierStatus;
	}

	public List<Long> getProtectTargetSoldierIds() {
		return protectTargetSoldierIds;
	}

	public void setProtectTargetSoldierIds(List<Long> protectTargetSoldierIds) {
		this.protectTargetSoldierIds = protectTargetSoldierIds;
	}

	public List<VideoInsideSkillAction> getProtectActions() {
		return protectActions;
	}

	public void setProtectActions(List<VideoInsideSkillAction> protectActions) {
		this.protectActions = protectActions;
	}

	public void addProtectAction(VideoTargetState targetState) {
		this.protectActions.add(new VideoInsideSkillAction(targetState));
	}

	public void addProtectTargetSoldierIds(long soldierId) {
		this.protectTargetSoldierIds.add(soldierId);
	}

	public int getSpSpent() {
		return spSpent;
	}

	public void setSpSpent(int spSpent) {
		this.spSpent = spSpent;
	}

	public int getMagicManaSpent() {
		return magicManaSpent;
	}

	public void setMagicManaSpent(int magicManaSpent) {
		this.magicManaSpent = magicManaSpent;
	}

	public Set<Integer> getPassiveSkillId() {
		return passiveSkillId;
	}

	public void setPassiveSkillId(Set<Integer> passiveSkillId) {
		this.passiveSkillId = passiveSkillId;
	}

	public void addPassiveSkillId(int passiveSkillId) {
		this.passiveSkillId.add(passiveSkillId);
	}
}
