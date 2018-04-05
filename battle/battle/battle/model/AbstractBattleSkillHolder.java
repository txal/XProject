package com.nucleus.logic.core.modules.battle.model;

import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.faction.dto.FactionSkillDto;

/**
 * 
 * @author Omanhom
 *
 */
public abstract class AbstractBattleSkillHolder<BU extends BattleUnit> extends BattleSkillHolder<BU> {
	public AbstractBattleSkillHolder(BU battleUnit) {
		super(battleUnit);
		initDefaultSkill();
	}

	public void initDefaultSkill() {
		this.activeSkillsMap.put(defaultActiveSkill.getId(), defaultActiveSkill);
		Skill defenseSkill = Skill.defenseSkill();
		Skill protectSkill = Skill.defaultProtectSkill();
		Skill retreatSkill = Skill.retreatSkill();
		Skill useItemSkill = Skill.useItemSkill();
		this.activeSkillsMap.put(defenseSkill.getId(), defenseSkill);
		this.activeSkillsMap.put(protectSkill.getId(), protectSkill);
		this.activeSkillsMap.put(retreatSkill.getId(), retreatSkill);
		this.activeSkillsMap.put(useItemSkill.getId(), useItemSkill);
		this.skillsLevelMap.put(this.defaultActiveSkill.getId(), 1);
	}

	@Override
	public Skill aiSkill() {
		int defaultSkillId = battleUnit.defaultSkillId();
		Skill skill = this.activeSkill(defaultSkillId);
		return skill != null ? skill : Skill.defaultActiveSkill();
	}

	@Override
	public void onFactionSkillUpgrade(FactionSkillDto fsDto) {
	}

	@Override
	public void populateEquipmentSkill() {
	}
}
