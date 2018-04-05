package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.AppSkillActionStatusCode;
import com.nucleus.logic.core.modules.battle.data.Monster;
import com.nucleus.logic.core.modules.battle.model.BattlePlayer;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 捕捉
 * 
 * @author liguo
 * 
 */
@Service
public class SkillLogic_5 extends SkillLogicAdapter {

	@Override
	protected int beforeFired(CommandContext commandContext) {
		int code = super.beforeFired(commandContext);
		if (code != AppSkillActionStatusCode.Ordinary)
			return code;
		// 判断是否可捕捉
		BattleSoldier target = commandContext.target();
		if (target != null && !target.isDead() && !target.isLeave()) {
			Monster monster = Monster.get(target.monsterId());
			if (monster == null || monster.getPetId() <= 0)
				code = AppSkillActionStatusCode.CatchPetFailure;
			else {
				BattlePlayer player = commandContext.trigger().player();
				if (player != null) {
					if (player.getGrade() < monster.pet().getCompanyLevel())
						code = AppSkillActionStatusCode.CatchPetLevelNotSuit;
					else {
						if (player.carryPetFull())
							code = AppSkillActionStatusCode.CarryPetFull;

					}
				}
			}
		} else {
			code = AppSkillActionStatusCode.CatchPetFailure;
		}
		commandContext.skillAction().setSkillStatusCode(code);
		return code;
	}

	@Override
	public void doFired(CommandContext commandContext) {
		BattleSoldier target = commandContext.target();
		if (target == null || target.isDead())
			return;
		commandContext.trigger().battle().capturePet(commandContext);
	}
}
