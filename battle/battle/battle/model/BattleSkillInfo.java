package com.nucleus.logic.core.modules.battle.model;

import com.nucleus.logic.core.modules.battle.data.Skill;

public class BattleSkillInfo {
	private long soldierId;
	private int skillId;
	private long targetSoldierId;
	private boolean isDead = false;

	public int getSkillId() {
		return skillId;
	}

	public void setSkillId(int skillId) {
		this.skillId = skillId;
	}

	public Skill skill() {
		return Skill.get(skillId);
	}

	@Override
	public String toString() {
		StringBuilder sb = new StringBuilder();
		sb.append("id=").append(getSoldierId());
		sb.append(",skillId=").append(skillId);
		sb.append(",target=").append(getTargetSoldierId());
		return sb.toString();
	}

	public long getTargetSoldierId() {
		return targetSoldierId;
	}

	public void setTargetSoldierId(long targetSoldierId) {
		this.targetSoldierId = targetSoldierId;
	}

	public long getSoldierId() {
		return soldierId;
	}

	public void setSoldierId(long soldierId) {
		this.soldierId = soldierId;
	}

	public boolean isDead() {
		return isDead;
	}

	public void setDead(boolean isDead) {
		this.isDead = isDead;
	}

	// public boolean legal(Soldier trigger) {
	// if (Skill.defenseSkillId() == this.skillId)
	// return true;
	// Game game = trigger.getGame();
	// RoundSoldier aRoundSoldier = game.getGameInfo().getAContingent().current();
	// RoundSoldier bRoundSoldier = game.getGameInfo().getBContingent().current();
	// if (aRoundSoldier == null || bRoundSoldier == null)
	// return false;
	// List<Long> removeSoldierIds = new ArrayList<Long>();
	//
	// for (long targetId : targetSet) {
	// if (!aRoundSoldier.contain(targetId) && !bRoundSoldier.contain(targetId)) {
	// removeSoldierIds.add(targetId);
	// }
	// }
	// for (long targetId : removeSoldierIds)
	// targetSet.remove(targetId);
	// return CollectionUtils.isNotEmpty(this.targetSet);
	// }

}
