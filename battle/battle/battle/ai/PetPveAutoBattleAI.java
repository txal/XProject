package com.nucleus.logic.core.modules.battle.ai;

import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.data.Monster.MonsterType;
import com.nucleus.logic.core.modules.battle.model.BattlePlayer;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.BattleTeam;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battle.model.PveBattle;

/**
 * 宠物在pve自动战斗中,如果主角自动抓捕,则宠物自动防御
 * 
 * @author wgy
 *
 */
public class PetPveAutoBattleAI extends BattleAIAdapter {
	private final BattleSoldier soldier;

	public PetPveAutoBattleAI(final BattleSoldier soldier) {
		this.soldier = soldier;
	}

	@Override
	public CommandContext selectCommand() {
		if (!(soldier.battle() instanceof PveBattle) || (!soldier.ifPet() && !soldier.ifChild()))
			return defaultCommand();
		BattleSoldier main = this.soldier.battleTeam().battleSoldier(this.soldier.playerId());// 取回主角
		if (main != null) {
			CommandContext commandContext = main.getCommandContext();
			if (commandContext != null) {// 如果主角已经设置好捕捉指令,则宠物使用防御指令
				if (commandContext.skill().getId() == Skill.captureSkill().getId())
					return new CommandContext(this.soldier, Skill.defenseSkill(), null);// 如果主角使用抓捕技能,则宠物防御
				else
					return defaultCommand();// 如果主角明确不使用捕捉技能,则宠物使用默认技能
			}
		}
		// 主角还未设置好指令的情况,则宠物自己判断当前情况:如果有宠物且可捕捉则防御
		// Player player = H1PlayerManager.getInstance().getOnlinePlayerById(this.soldier.playerId());
		BattlePlayer player = this.soldier.player();
		if (player != null) {
			if (player.carryPetFull())
				return defaultCommand();
			// PersistPlayerCharactor playerCharactorInfo = player.persistPlayerCharactor();
			// if (playerCharactorInfo.carryPetFull())
			// return defaultCommand();
		}
		BattleTeam enemyTeam = soldier.battleTeam().getEnemyTeam();
		for (BattleSoldier soldier : enemyTeam.soldiersMap().values()) {
			if (soldier.getMonsterType() == MonsterType.Baobao.ordinal() || soldier.getMonsterType() == MonsterType.Mutate.ordinal()) {
				return new CommandContext(this.soldier, Skill.defenseSkill(), null);
			}
		}
		return defaultCommand();
	}

	private CommandContext defaultCommand() {
		return new CommandContext(soldier, this.soldier.skillHolder().aiSkill(), null);
	}
}
