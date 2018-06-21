package com.nucleus.logic.core.modules.battle.logic;

import java.util.Collections;
import java.util.Comparator;
import java.util.List;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 选择物理防御最高
 * 
 * @author hwy
 *
 */
@Service
public class TargetSelectLogic_7 extends AbstractTargetSelectLogic {
	/**
	 * 防御最高的单位，相同比例情况下对面位置>位置1>位置2>位置3
	 */
	public final static Comparator<BattleSoldier> defComparator = new Comparator<BattleSoldier>() {
		@Override
		public int compare(BattleSoldier o1, BattleSoldier o2) {
			int def1 = o1.def();
			int def2 = o2.def();
			if (def1 < def2)
				return 1;
			if (def1 > def2)
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
		Collections.sort(fitList, defComparator);
		return fitList.get(0);
	}
}
