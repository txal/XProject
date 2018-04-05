package com.nucleus.logic.core.modules.battle.ai;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Set;

import com.nucleus.commons.utils.RandomUtils;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.data.Monster.MonsterType;
import com.nucleus.logic.core.modules.battle.model.BattlePlayer;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.BattleTeam;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battle.model.PveBattle;

/**
 * 玩家在pve战斗中自动战斗ai:如果对方有宝宝则使用捕捉指令
 * 
 * @author wgy
 *
 */
public class PlayerPveAutoBattleAI extends BattleAIAdapter {
	private final BattleSoldier soldier;

	public PlayerPveAutoBattleAI(final BattleSoldier soldier) {
		this.soldier = soldier;
	}

	@Override
	public CommandContext selectCommand() {
		if (!(soldier.battle() instanceof PveBattle) || !soldier.ifMainCharactor())
			return defaultCommand();
		if (soldier.battle().getCount() > 1) {// 大于2回合不再自动捕捉
			return defaultCommand();
		}
		// Player player = H1PlayerManager.getInstance().getOnlinePlayerById(this.soldier.playerId());
		BattlePlayer player = this.soldier.player();
		if (player == null)
			return defaultCommand();
		if (player.carryPetFull())
			return defaultCommand();
		Set<Integer> rareMonsterIds = getRareMonsterIds();
		BattleTeam enemyTeam = soldier.battleTeam().getEnemyTeam();
		List<BattleSoldier> targets = new ArrayList<BattleSoldier>();
		for (BattleSoldier soldier : enemyTeam.soldiersMap().values()) {
			if (soldier.getMonsterType() == MonsterType.Baobao.ordinal() || soldier.getMonsterType() == MonsterType.Mutate.ordinal() || rareMonsterIds.contains(soldier.monsterId()))
				targets.add(soldier);
		}
		CommandContext commandContext = null;
		if (!targets.isEmpty()) {
			BattleSoldier target = RandomUtils.next(targets);
			commandContext = new CommandContext(soldier, Skill.captureSkill(), target);
		} else {// 没有宝宝的时候执行普通ai
			commandContext = defaultCommand();
		}
		return commandContext;
	}

	private Set<Integer> getRareMonsterIds() {
		BattlePlayer bp = this.soldier.player();
		if (bp != null) {
			return bp.currentScene().sceneMap().rareMonsterMap().keySet();
		}
		return Collections.emptySet();
	}

	private CommandContext defaultCommand() {
		return new CommandContext(soldier, this.soldier.skillHolder().aiSkill(), null);
	}
}
