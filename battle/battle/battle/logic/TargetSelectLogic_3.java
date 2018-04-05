package com.nucleus.logic.core.modules.battle.logic;

import java.util.Comparator;
import java.util.List;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 优先选择速度最快那个目标
 * 
 * @author wgy
 *
 */
@Service
public class TargetSelectLogic_3 extends AbstractTargetSelectLogic {
	public final static Comparator<BattleSoldier> speedComparator = new Comparator<BattleSoldier>() {

		@Override
		public int compare(BattleSoldier o1, BattleSoldier o2) {
			final int speed1 = o1.speed();
			final int speed2 = o2.speed();
			if (speed1 > speed2)
				return -1;
			else if (speed1 < speed2)
				return 1;
			return 0;
		}
	};

	@Override
	protected BattleSoldier doSelect(List<BattleSoldier> fitList, CommandContext commandContext) {
		fitList.sort(speedComparator);
		return fitList.get(0);
	}

}
