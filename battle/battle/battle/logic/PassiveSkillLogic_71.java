package com.nucleus.logic.core.modules.battle.logic;

import java.util.Set;

import org.apache.commons.collections.CollectionUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.nucleus.commons.utils.RandomUtils;
import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.manager.TargetSelectLogicManager;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 用指定技能攻击符合条件目标
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLogic_71 extends AbstractPassiveSkillLogic {
	@Autowired
	private TargetSelectLogicManager logicManager;

	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		if (config.getExtraParams() == null || config.getExtraParams().length <= 0)
			return;
		Set<Integer> skillIds = SplitUtils.split2IntSet(config.getExtraParams()[0], ",");
		if (CollectionUtils.isEmpty(skillIds))
			return;
		int skillId = skillIds.size() > 1 ? RandomUtils.next(skillIds) : skillIds.iterator().next();
		int selectLogicId = Integer.parseInt(config.getExtraParams()[1]);
		Skill skill = Skill.get(skillId);
		if (skill == null)
			return;
		ITargetSelectLogic logic = logicManager.getLogic(selectLogicId);
		if (logic == null)
			return;
		final CommandContext checkContext = new CommandContext(soldier, skill, null);
		BattleSoldier t = logic.select(skill.skillAi().skillAiLogic().availableTargets(checkContext), checkContext, null);
		if (t == null)
			return;
		try {
			soldier.setAutoBattle(false);
			soldier.initCommandContext(new CommandContext(soldier, skill, t));
			soldier.actionStart();
		} catch (Exception e) {
			e.printStackTrace();
		}
	}
}
