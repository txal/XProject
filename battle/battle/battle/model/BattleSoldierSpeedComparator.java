package com.nucleus.logic.core.modules.battle.model;

import java.util.Comparator;

/**
 * 按照速度快->慢排序,速度相同按照经验小->大排序
 * 
 * @author wgy
 *
 */
public class BattleSoldierSpeedComparator implements Comparator<BattleSoldier> {

	@Override
	public int compare(BattleSoldier o1, BattleSoldier o2) {
		int s1 = o1.speed();
		int s2 = o2.speed();
		if (s1 > s2)
			return -1;
		else if (s1 < s2)
			return 1;
		else {
			long exp1 = o1.exp();
			long exp2 = o2.exp();
			if (exp1 > exp2)
				return 1;
			else if (exp1 < exp2)
				return -1;
		}
		return 0;
	}

}
