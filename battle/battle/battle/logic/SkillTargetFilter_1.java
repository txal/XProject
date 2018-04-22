package com.nucleus.logic.core.modules.battle.logic;

import java.util.Iterator;
import java.util.Map;
import java.util.Set;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;

/**
 * 鬼魂生物无效
 * 
 * @author wgy
 *
 */
@GenIgnored
public class SkillTargetFilter_1 extends AbstractSkillTargetFilter {
	private Set<Integer> skillIds;

	@Override
	public Map<Long, BattleSoldier> filter(Map<Long, BattleSoldier> targets) {
		if (this.skillIds == null || this.skillIds.isEmpty())
			return targets;
		for (Iterator<BattleSoldier> it = targets.values().iterator(); it.hasNext();) {
			BattleSoldier soldier = it.next();
			for (int skillId : skillIds) {
				Skill skill = soldier.skillHolder().skill(skillId);
				if (skill != null)
					it.remove();
			}
		}
		return targets;
	}

	public Set<Integer> getSkillIds() {
		return skillIds;
	}

	public void setSkillIds(Set<Integer> skillIds) {
		this.skillIds = skillIds;
	}

}
