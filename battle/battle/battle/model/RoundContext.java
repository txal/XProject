package com.nucleus.logic.core.modules.battle.model;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * 一回合中的上下文信息
 * <p>
 * Created by Tony on 15/7/6.
 */
public class RoundContext {

	public enum RoundState {
		RoundStart, RoundAction, RoundOver,
	}

	public class SkillSelectInfo {
		public long triggerId;
		public int skillId;

		public SkillSelectInfo(long triggerId, int skillId) {
			this.triggerId = triggerId;
			this.skillId = skillId;
		}
	}

	private RoundState state = RoundState.RoundStart;

	private int round = 0;

	private final Map<Long, SkillSelectInfo> skillTargets = new HashMap<>();
	/** 本会合受到伤害 key=soldierId, value=damage */
	private final Map<Long, Integer> damageInputs = new ConcurrentHashMap<>();

	public void clear() {
		skillTargets.clear();
		damageInputs.clear();
	}

	public boolean isTargetBySkill(long targetId, int skillId) {
		SkillSelectInfo info = skillTargets.get(targetId);
		if (info == null) {
			return false;
		}
		return (skillId == info.skillId);
	}

	public boolean isTargetBySkill(long targetId, long triggerId, int skillId) {
		SkillSelectInfo info = skillTargets.get(targetId);
		if (info == null) {
			return false;
		}
		return (triggerId == info.triggerId && skillId == info.skillId);
	}

	public SkillSelectInfo skillSelectInfo(long targetId) {
		return skillTargets.get(targetId);
	}

	public void putTarget(long soldierId, long triggerId, int skillId) {
		skillTargets.put(soldierId, new SkillSelectInfo(triggerId, skillId));
	}

	public RoundState getState() {
		return state;
	}

	public void setState(RoundState state) {
		this.state = state;
	}

	public int getRound() {
		return round;
	}

	public void setRound(int round) {
		this.round = round;
	}

	public void addDamageInput(long soldierId, int damage) {
		this.damageInputs.merge(soldierId, damage, (v1, v2) -> v1 + v2);
	}

	public int damageInputOf(long soldierId) {
		return this.damageInputs.getOrDefault(soldierId, 0);
	}
}
