package com.nucleus.logic.core.modules.battle.logic;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.Set;

import org.springframework.stereotype.Service;

import com.nucleus.commons.utils.RandomUtils;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 优先选择没有相同buff的目标
 * 
 * @author wgy
 *
 */
@Service
public class TargetSelectLogic_2 extends AbstractTargetSelectLogic {
	@Override
	protected BattleSoldier doSelect(List<BattleSoldier> fitList, CommandContext commandContext) {
		Skill skill = commandContext.skill();
		Set<Integer> buffIds = skill.targetBattleBuffIds();
		BattleSoldier target = null;
		if (buffIds == null || buffIds.isEmpty()) {
			target = RandomUtils.next(fitList);
		} else {
			List<BattleSoldier> backup = new ArrayList<BattleSoldier>();
			Iterator<BattleSoldier> it = fitList.iterator();
			while (it.hasNext()) {
				BattleSoldier soldier = it.next();
				for (Integer buffId : buffIds) {
					if (soldier.buffHolder().hasBuff(buffId)) {
						it.remove();
						backup.add(soldier);
						break;
					}
				}
			}
			if (!fitList.isEmpty())
				target = RandomUtils.next(fitList);
			else
				target = RandomUtils.next(backup);
		}
		return target;
	}

}
