/**
 * 
 */
package com.nucleus.logic.core.modules.battle.logic;

import org.apache.commons.lang3.StringUtils;
import org.springframework.stereotype.Service;

import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.dto.VideoSkillAction;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.faction.data.Faction;

/**
 * 死亡之后触发技能(死亡反击)
 * 
 * @author xitao.huang
 *
 */
@Service
public class PassiveSkillLogic_65 extends AbstractPassiveSkillLogic {

	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		if (!super.launchable(soldier, target, context, config, timing, passiveSkill))
			return false;
		if (!soldier.isMainCharactor())
			return false;
		if (timing == PassiveSkillLaunchTimingEnum.Dead && !soldier.isDead())
			return false;
		return true;
	}

	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		Skill skill = hasSkill(soldier, config);
		if (skill == null)
			skill = getFactionSkill(soldier);
		if (skill == null)
			return;
		VideoSkillAction strikeSkillAction = new VideoSkillAction(soldier.getId());
		context.setStrokeBack(true);
		context.skillAction().currentTargetStateGroup().setStrikeBackAction(strikeSkillAction);
		CommandContext newContext = new CommandContext(soldier, skill, target);
		newContext.setStrokeBack(true);
		newContext.setDeadStrokeBack(true);//死亡反击
		// newContext.setHiddenFail(false);// 可以反击隐身目标
		newContext.setStrikeSkillAction(strikeSkillAction);
		if (config.getExtraParams() != null && config.getExtraParams().length > 1)
			newContext.setCurDamageVaryRate(Float.parseFloat(config.getExtraParams()[1]));
		else
			newContext.setCurDamageVaryRate(1);
		CommandContext oldContext = soldier.getCommandContext();
		// if (oldContext != null)
		// soldier.setOldCommandContext(oldContext);
		soldier.initCommandContext(newContext);
		skill.fired(newContext);
		soldier.destoryCommandContext();
		if (oldContext != null)
			soldier.initCommandContext(oldContext);// 执行完反击把之前的指令设置回去
	}

	private Skill getFactionSkill(BattleSoldier soldier) {
		Faction faction = soldier.faction();
		if (faction != null) {
			return Skill.get(faction.getDefaultSkillId());
		}
		return null;
	}

	private Skill hasSkill(BattleSoldier soldier, PassiveSkillConfig config) {
		String[] extraParams = config.getExtraParams();
		if (extraParams != null && extraParams.length > 0 && StringUtils.isNotBlank(extraParams[0])) {
			int[] skillIds = SplitUtils.split2IntArray(extraParams[0], ",");
			Skill skill = null;
			for (int skillId : skillIds) {
				skill = soldier.skillHolder().skill(skillId);
				if (skill != null)
					return skill;
			}
		}
		return null;
	}
}
