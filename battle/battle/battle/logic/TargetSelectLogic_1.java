package com.nucleus.logic.core.modules.battle.logic;

import java.util.Collections;
import java.util.Comparator;
import java.util.List;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 选择血量比例最小
 * 
 * @author wgy
 *
 */
@Service
public class TargetSelectLogic_1 extends AbstractTargetSelectLogic {
	/**
	 * HP/maxHp比例最少的单位，相同比例情况下对面位置>位置1>位置2>位置3
	 */
	public final static Comparator<BattleSoldier> hpComparator = new Comparator<BattleSoldier>() {
		@Override
		public int compare(BattleSoldier o1, BattleSoldier o2) {
			float hpRate1 = (float) o1.hp() / o1.maxHp();
			float hpRate2 = (float) o2.hp() / o2.maxHp();
			if (hpRate1 > hpRate2)
				return 1;
			if (hpRate1 < hpRate2)
				return -1;
			int position1 = o1.getPosition();
			int position2 = o2.getPosition();
			if (position1 > position2)
				return 1;
			if (position1 < position2)
				return -1;
			return 0;
		}
	};

	@Override
	protected BattleSoldier doSelect(List<BattleSoldier> fitList, CommandContext commandContext) {
		Collections.sort(fitList, hpComparator);
		return fitList.get(0);
	}
}
