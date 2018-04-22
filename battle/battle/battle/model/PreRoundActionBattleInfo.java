package com.nucleus.logic.core.modules.battle.model;

import java.util.ArrayList;
import java.util.List;

/**
 * 回合前置行动
 * 
 * @author wgy
 *
 */
public class PreRoundActionBattleInfo extends DefaultBattleInfo {
	private List<BattleSoldier> preActionSoldiers;

	public PreRoundActionBattleInfo() {
		this.preActionSoldiers = new ArrayList<BattleSoldier>();
	}

	@Override
	public List<BattleSoldier> preRoundActionQueue() {
		return this.preActionSoldiers;
	}
}
