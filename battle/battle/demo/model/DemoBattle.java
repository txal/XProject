package com.nucleus.logic.core.modules.demo.model;

import com.nucleus.logic.core.modules.battle.data.Monster;
import com.nucleus.logic.core.modules.battle.dto.Video;
import com.nucleus.logic.core.modules.battle.model.BattlePlayer;
import com.nucleus.logic.core.modules.battle.model.BattleTeam;
import com.nucleus.logic.core.modules.battle.model.PveBattle;
import com.nucleus.logic.core.modules.demo.dto.DemoVideo;

/**
 * 战斗Demo
 * 
 * @author liguo
 * 
 */
public class DemoBattle extends PveBattle {
	private Monster monster;
	private int amount;

	public DemoBattle(Monster monster, int amount, BattlePlayer player) {
		super(player);
		this.monster = monster;
		this.amount = amount;
	}

	@Override
	protected BattleTeam initBteam() {
		return new BattleTeam(this.monster, this.amount, this);
	}

	@Override
	protected Video createVideo() {
		return new DemoVideo(this.maxRound());
	}

	@Override
	protected void battleFinish(BattleTeam winTeam, BattleTeam loseTeam) {
		super.battleFinish(winTeam, loseTeam);
	}
}
