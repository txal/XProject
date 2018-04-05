package com.nucleus.logic.core.modules.battle.logic;

import java.util.HashMap;
import java.util.Map;

import com.nucleus.commons.utils.RandomUtils;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.data.PetPassiveSkill;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.dto.VideoActionTargetSkillState;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff.BattleBasePropertyType;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;
import com.nucleus.logic.core.modules.equipment.data.EquipmentPassiveSkill;
import com.nucleus.player.service.ScriptService;

public abstract class AbstractPassiveSkillLogic implements IPassiveSkillLogic {
	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		if (config.getLaunchTiming() != timing.ordinal())
			return false;
		if (config.launchConditions() == null || config.launchConditions().isEmpty())
			return true;
		for (AbstractPassiveSkillLaunchCondition con : config.launchConditions()) {
			if (!con.launchable(soldier, target, context, passiveSkill))
				return false;
		}
		return true;
	}

	@Override
	public void apply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		if (!launchable(soldier, target, context, config, timing, passiveSkill))
			return;
		doApply(soldier, target, context, config, timing, passiveSkill);
		afterApply(soldier, target, context, config, timing, passiveSkill);
	}

	protected void afterApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		soldier.increaseUsedSkillTimes(passiveSkill.getId());
		soldier.addRoundPassiveEffectTime(config.getId());
		this.passiveSkillAction(soldier, target, context, config, timing, passiveSkill);
	}

	protected void passiveSkillAction(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		if (soldier.battle().getVideo() == null)
			return;
		if (passiveSkill instanceof PetPassiveSkill) {
			PetPassiveSkill petPassiveSkill = (PetPassiveSkill) passiveSkill;
			if (!petPassiveSkill.isSkillText())
				return;
			if (config.getSelfBuff() > 0 && config.getTargetBuff() > 0)
				return;
		} else if (passiveSkill instanceof EquipmentPassiveSkill) {
			EquipmentPassiveSkill equipmentPassiveSkill = (EquipmentPassiveSkill) passiveSkill;
			if (!equipmentPassiveSkill.isSkillText())
				return;
		} else {
			return;
		}
		VideoActionTargetSkillState state = new VideoActionTargetSkillState(soldier, passiveSkill.getId());
		if (timing == PassiveSkillLaunchTimingEnum.RoundStart) {
			soldier.currentVideoRound().readyAction().addTargetState(state);
		} else if (context != null) {
			context.skillAction().addTargetState(state);
		} else if (soldier.getCommandContext() != null) {
			soldier.getCommandContext().skillAction().addTargetState(state);
		}
	}

	@Override
	public float propertyEffect(BattleSoldier soldier, BattleBasePropertyType property, PassiveSkillConfig config, IPassiveSkill passiveSkill) {
		return 0;
	}

	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {

	}

	protected BattleBuffEntity addBuff(BattleSoldier soldier, BattleSoldier target, int skillId, BattleBuff buff) {
		if (buff == null)
			return null;
		float buffRate = getBuffRate(soldier, target, skillId, buff.getBuffsAcquireRateFormula());
		boolean isBuffAcquired = RandomUtils.baseRandomHit(buffRate);
		if (!isBuffAcquired)
			return null;
		Map<String, Object> params = new HashMap<String, Object>();
		params.put("RandomUtils", RandomUtils.getInstance());
		params.put("trigger", soldier);
		params.put("skillLevel", soldier.skillLevel(skillId));
		params.put("target", target);
		int persistRound = ScriptService.getInstance().calcuInt("", buff.getBuffsPersistRoundFormula(), params, false);
		if (persistRound > 0) {
			BattleBuffEntity buffEntity = new BattleBuffEntity(buff, soldier, target, skillId, persistRound);
			if (target.buffHolder().addBuff(buffEntity))
				return buffEntity;
		}
		return null;
	}

	private float getBuffRate(BattleSoldier trigger, BattleSoldier target, int skillId, String formula) {
		Map<String, Object> params = new HashMap<String, Object>();
		params.put("trigger", trigger);
		params.put("target", target);
		params.put("skillLevel", trigger.skillLevel(skillId));
		float rate = ScriptService.getInstance().calcuFloat("", formula, params, false);
		return rate;
	}

	protected void magicCombo(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		Skill skill = context.skill();
		float rate = 1;
		if (config.getExtraParams() != null) {
			try {
				rate = Float.parseFloat(config.getExtraParams()[0]);
			} catch (Exception e) {
				e.printStackTrace();
			}
		}
		CommandContext newCommandContext = new CommandContext(soldier, skill, target);
		newCommandContext.setCurDamageVaryRate(rate);
		newCommandContext.setCombo(true);
		soldier.initCommandContext(newCommandContext);
		skill.fired(newCommandContext);
		soldier.destoryCommandContext();
	}

	protected void defineSkillCombo(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, int skillId) {
		Skill skill = Skill.get(skillId);
		float rate = 1;
		if (config.getExtraParams() != null) {
			try {
				rate = Float.parseFloat(config.getExtraParams()[1]);
			} catch (Exception e) {
				e.printStackTrace();
			}
		}
		CommandContext newCommandContext = new CommandContext(soldier, skill, target);
		newCommandContext.setCurDamageVaryRate(rate);
		newCommandContext.setCombo(true);
		soldier.initCommandContext(newCommandContext);
		skill.fired(newCommandContext);
		soldier.destoryCommandContext();
	}
}
