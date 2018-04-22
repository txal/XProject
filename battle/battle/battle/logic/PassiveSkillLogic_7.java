package com.nucleus.logic.core.modules.battle.logic;

import java.util.HashMap;
import java.util.Map;

import org.springframework.stereotype.Service;

import com.nucleus.commons.utils.RandomUtils;
import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.dto.VideoSkillAction;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.player.service.ScriptService;

/**
 * 反击
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLogic_7 extends AbstractPassiveSkillLogic {

	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		if (!super.launchable(soldier, target, context, config, timing, passiveSkill))
			return false;
		if (context.isStrokeBack())
			return false;
		// 做成可配置条件：id=38
		// if (!context.skill().isStrikebackable())
		// return false;//当前技能不能被反击
		return true;
	}

	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		int[] skillIds = SplitUtils.split2IntArray(config.getExtraParams()[0], ",");
		int idx = RandomUtils.nextInt(0, skillIds.length - 1);
		int skillId = skillIds[idx];
		Skill skill = Skill.get(skillId);
		if (skill == null)
			return;
		VideoSkillAction strikeSkillAction = new VideoSkillAction(soldier.getId());
		context.setStrokeBack(true);
		context.skillAction().currentTargetStateGroup().setStrikeBackAction(strikeSkillAction);
		CommandContext newContext = new CommandContext(soldier, skill, target);
		newContext.setStrokeBack(true);
		newContext.setHiddenFail(true);// 可以反击隐身目标
		newContext.setStrikeSkillAction(strikeSkillAction);
		if (config.getExtraParams().length > 1) {
			Map<String, Object> params = new HashMap<String, Object>();
			params.put("skillLevel", soldier.skillLevel(skillId));
			params.put("pasSkillLevel", soldier.skillLevel(passiveSkill.getId()));
			float damageVaryRate = ScriptService.getInstance().calcuFloat("", config.getExtraParams()[1], params, false);
			newContext.setCurDamageVaryRate(damageVaryRate);
		} else {
			newContext.setCurDamageVaryRate(1);
		}
		CommandContext oldContext = soldier.getCommandContext();
		// if (oldContext != null)
		// soldier.setOldCommandContext(oldContext);
		soldier.initCommandContext(newContext);
		skill.fired(newContext);
		soldier.destoryCommandContext();
		if (oldContext != null)
			soldier.initCommandContext(oldContext);// 执行完反击把之前的指令设置回去
	}
}
