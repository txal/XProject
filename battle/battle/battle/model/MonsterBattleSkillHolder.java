/**
 * 
 */
package com.nucleus.logic.core.modules.battle.model;

import com.nucleus.logic.core.modules.battle.data.Monster;

/**
 * @author liguo
 * 
 */
public class MonsterBattleSkillHolder extends NpcBattleSkillHolder<Monster> {

	public MonsterBattleSkillHolder(Monster battleUnit) {
		super(battleUnit);
		this.skillsWeight = battleUnit.skillsWeight();
		populateActiveSkills();
		populatePassiveSkills(battleUnit.getPassiveSkills());
	}
}
