package com.nucleus.logic.core.modules.battle.model;

import java.util.List;
import java.util.Set;

import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.data.SkillWeightInfo;
import com.nucleus.logic.core.modules.battle.data.SkillsWeight;
import com.nucleus.logic.core.modules.faction.dto.FactionSkillDto;

public abstract class NpcBattleSkillHolder<BU extends BattleUnit> extends BattleSkillHolder<BU> {

	public NpcBattleSkillHolder(BU battleUnit) {
		super(battleUnit);
	}

	/** 技能施放权重 */
	protected SkillsWeight skillsWeight;

	@Override
	public Skill aiSkill() {
		return randomActiveSkill();
	}

	private Skill randomActiveSkill() {
		Skill resultSkill = activeSkill(skillsWeight.randomeSkillId());
		if (null == resultSkill)
			resultSkill = this.defaultActiveSkill;
		return resultSkill;
	}

	protected void populateActiveSkills() {
		if (null == this.skillsWeight)
			return;
		List<SkillWeightInfo> skillWeightInfos = skillsWeight.skillWeightInfos();
		if (null == skillWeightInfos || skillWeightInfos.isEmpty())
			return;
		int skillLevel = this.battleUnit.grade();
		for (int i = 0; i < skillWeightInfos.size(); i++) {
			SkillWeightInfo skillWeightInfo = skillWeightInfos.get(i);
			Skill skill = skillWeightInfo.skill();
			if (skill == null)
				continue;
			this.activeSkillsMap.put(skill.getId(), skill);
			this.skillsLevelMap.put(skill.getId(), skillLevel);
		}
	}

	protected void populatePassiveSkills(Set<Integer> skills) {
		if (skills == null || skills.isEmpty())
			return;
		this.passiveSkillsMap.clear();
		for (int skillId : skills) {
			Skill skill = Skill.get(skillId);
			if (skill != null) {
				this.passiveSkillsMap.put(skillId, skill);
			}
		}
	}

	@Override
	public void onFactionSkillUpgrade(FactionSkillDto fsDto) {
	}

	@Override
	public void populateEquipmentSkill() {
	}

	@Override
	public int skillLevel(int skillId) {
		return battleUnit.grade();// npc的技能等级=自身等级
	}

	public SkillsWeight getSkillsWeight() {
		return skillsWeight;
	}

	public void setSkillsWeight(SkillsWeight skillsWeight) {
		this.skillsWeight = skillsWeight;
	}
}
