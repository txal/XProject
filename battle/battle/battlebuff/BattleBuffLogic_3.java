package com.nucleus.logic.core.modules.battlebuff;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.logic.ITargetSelectLogic;
import com.nucleus.logic.core.modules.battle.logic.SkillAiLogic;
import com.nucleus.logic.core.modules.battle.manager.SkillAiLogicManager;
import com.nucleus.logic.core.modules.battle.manager.TargetSelectLogicManager;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;
import com.nucleus.logic.core.modules.battlebuff.model.BuffLogicParam;
import com.nucleus.logic.core.modules.battlebuff.model.BuffLogicParam_3;

/**
 * 疯狂:中此buff忽略任何指令,随机普通攻击敌方目标
 * 
 * @author wgy
 *
 */
@Service
public class BattleBuffLogic_3 extends BattleBuffLogicAdapter {

	@Override
	protected BuffLogicParam newParam() {
		return new BuffLogicParam_3();
	}

	@Override
	public void onActionStart(CommandContext commandContext, BattleBuffEntity buffEntity) {
		commandContext.setSkill(Skill.defaultActiveSkill());
		BuffLogicParam_3 param = (BuffLogicParam_3) buffEntity.battleBuff().getBuffParam();
		SkillAiLogic aiLogic = SkillAiLogicManager.getInstance().getLogic(param.getAiLogicId());
		ITargetSelectLogic selectLogic = TargetSelectLogicManager.getInstance().getLogic(param.getSelectTargetLogicId());
		BattleSoldier target = selectLogic.select(aiLogic.availableTargets(commandContext), commandContext, null);
		if (target != null)
			commandContext.populateTarget(target);
	}
}
