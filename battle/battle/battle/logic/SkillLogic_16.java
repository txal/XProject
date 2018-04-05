package com.nucleus.logic.core.modules.battle.logic;

import java.util.ArrayList;
import java.util.List;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 多段攻击
 * 
 * @author hwy
 * 
 */
@Service
public class SkillLogic_16 extends SkillLogic_1 {

	@Override
	protected void addSelfBuff(CommandContext commandContext) {
		// 多端攻击触发结束后再添加buff
		Skill skill = commandContext.skill();
		int skillCombo = skill.comboTargetInfoList().size();
		if (!commandContext.isCombo() && skillCombo > 0)
			commandContext.setCombo(true);

		int comboIndex = commandContext.getComboIndex();
		if (comboIndex < skillCombo) {
			BattleSoldier target = commandContext.target();
			if (target == null) {
				super.addSelfBuff(commandContext);
				return;
			}
			if (commandContext.debugEnable())
				commandContext.initDebugInfo(commandContext.trigger(), commandContext.skill(), target);
			BattleSoldier trigger = commandContext.trigger();

			List<SkillTargetPolicy> comboTargetPolicys = new ArrayList<>();
			List<SkillTargetInfo> skillTargetInfoList = skill.comboTargetInfoList().get(comboIndex).getSkillTargetInfoList();
			List<SkillTargetPolicy> targetPolicys = commandContext.getTargetPolicys();
			for (int i = 0; i < targetPolicys.size(); i++) {
				SkillTargetPolicy policy = targetPolicys.get(i);
				if (i >= skillTargetInfoList.size())
					break;
				if (policy.getTarget().isDead())
					continue;
				comboTargetPolicys.add(new SkillTargetPolicy(policy.getTarget(), skillTargetInfoList.get(i)));
			}
			if (comboTargetPolicys.isEmpty()) {
				super.addSelfBuff(commandContext);
				return;
			}

			CommandContext newCommandContext = new CommandContext(commandContext.trigger(), skill, target);
			newCommandContext.setCurDamageVaryRate(commandContext.getCurDamageVaryRate());
			newCommandContext.setPursueAttack(true);
			newCommandContext.setCombo(commandContext.isCombo());
			newCommandContext.setComboIndex(++comboIndex);
			newCommandContext.setComboTargetPolicys(comboTargetPolicys);
			trigger.initCommandContext(newCommandContext);
			skill.fired(newCommandContext);
			trigger.destoryCommandContext();

			newCommandContext.clearComboTargetPolicys();
		} else {
			super.addSelfBuff(commandContext);
		}
	}
}
