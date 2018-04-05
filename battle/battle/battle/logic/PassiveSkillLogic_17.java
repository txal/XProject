package com.nucleus.logic.core.modules.battle.logic;

import java.util.HashMap;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.dto.VideoBuffAddTargetState;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;
import com.nucleus.player.service.ScriptService;

/**
 * 强制目标使用某技能
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLogic_17 extends AbstractPassiveSkillLogic {
	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		if (context == null)
			return;
		if (target == null || target.isLeave())
			return;
		String skillStr = config.getExtraParams()[0];
		int skillId = Integer.parseInt(skillStr);
		Skill skill = Skill.get(skillId);
		if (skill == null)
			return;
		int nextRound = target.battle().getCount() + 1;
		target.initForceSkill(skillId, nextRound);
		if (config.getTargetBuff() > 0) {
			BattleBuff buff = BattleBuff.get(config.getTargetBuff());
			if (buff != null) {
				int persistRound = ScriptService.getInstance().calcuInt("BattleUtils.buffRounds", buff.getBuffsPersistRoundFormula(), new HashMap<String, Object>(), false);
				if (persistRound > 0) {
					BattleBuffEntity buffEntity = new BattleBuffEntity(buff, soldier, target, passiveSkill.getId(), persistRound);
					target.buffHolder().addBuff(buffEntity);
					context.skillAction().addTargetState(new VideoBuffAddTargetState(buffEntity));
				}
			}
		}
	}
}
