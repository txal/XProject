/**
 * 
 */
package com.nucleus.logic.core.modules.demo;

import com.nucleus.logic.core.modules.battle.dto.PvpTypeEnum;
import com.nucleus.logic.core.modules.battle.model.BattlePlayer;
import com.nucleus.logic.core.modules.battle.model.PvpBattle;

/**
 * @author Omanhom
 *
 */
public class DemoPvp extends PvpBattle {

	public DemoPvp(BattlePlayer p1, BattlePlayer p2) {
		super(p1, p2);
	}

	@Override
	public int getType() {
		return PvpTypeEnum.Normal.ordinal();
	}
}
