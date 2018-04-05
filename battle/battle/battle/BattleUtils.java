/**
 * 
 */
package com.nucleus.logic.core.modules.battle;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.apache.commons.lang3.StringUtils;
import org.apache.commons.logging.LogFactory;

import com.nucleus.commons.utils.RandomUtils;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.data.SkillWeightInfo;
import com.nucleus.logic.core.modules.battle.data.SkillsWeight;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffContext;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;
import com.nucleus.logic.core.modules.faction.data.FactionSkill;
import com.nucleus.player.service.ScriptService;

/**
 * @author liguo
 * 
 */
public class BattleUtils {
	public final static int DENOMINATOR = 10000;

	public static float valueWithSoldierFactionSkill(BattleSoldier soldier, String formula, FactionSkill skill) {
		float effectValue = 0;
		if (StringUtils.isBlank(formula))
			return effectValue;
		try {
			Map<String, Object> paramMap = new HashMap<>();
			paramMap.put("trigger", soldier);
			if (skill != null)
				paramMap.put("factionSkillLevel", soldier.skillHolder().factionSkillLevel(skill.getId()));
			effectValue = ScriptService.getInstance().calcuFloat("BattleUtils.valueWithSoldierFactionSkill", formula, paramMap, true);
		} catch (Exception ex) {
			StringBuilder sb = new StringBuilder();
			sb.append("battleSoldierId:").append(soldier.getId());
			sb.append(",formula:").append(formula);
			LogFactory.getLog("error.log").error(sb.toString(), ex);
		}
		return effectValue;
	}

	public static int buffRounds(CommandContext commandContext, BattleSoldier target, String formula) {
		int rounds = 0;
		if (StringUtils.isBlank(formula))
			return rounds;
		Skill skill = commandContext.skill();
		int skillId = skill.getId();
		if (skillId == Skill.SPECIAL_SKILL_ID_BACKUP)
			skillId = Skill.SPECIAL_SKILL_ID;// 觉醒后备技能并不存在于战斗单位身上，因此觉醒后备技能应该换回正式技能
		int skillLevel = commandContext.trigger().skillLevel(skillId);
		try {
			Map<String, Object> paramMap = new HashMap<>();
			paramMap.put("target", target);
			paramMap.put("trigger", commandContext.trigger());
			paramMap.put("skillLevel", skillLevel);
			paramMap.put("RandomUtils", RandomUtils.getInstance());
			rounds = ScriptService.getInstance().calcuInt("BattleUtils.buffRounds", formula, paramMap, false);
		} catch (Exception ex) {
			ex.printStackTrace();
		}
		return rounds;
	}

	public static float valueWithSoldierSkill(BattleSoldier soldier, String formula, Skill skill) {
		float effectValue = 0;
		if (StringUtils.isBlank(formula))
			return effectValue;
		try {
			StringBuilder sb = new StringBuilder();
			sb.append("soldierId:").append(soldier.getId());
			Map<String, Object> paramMap = new HashMap<>();
			paramMap.put("trigger", soldier);
			paramMap.put("RandomUtils", RandomUtils.getInstance());
			if (skill != null) {
				paramMap.put("skillLevel", soldier.skillLevel(skill.getId()));
				sb.append(", skillId:").append(skill.getId());
				// int factionSkillLevel = soldier.battleUnit().battleSkillHolder().playerFactionSkillLevel(skill.getFactionSkillId());
				int factionSkillLevel = soldier.skillHolder().factionSkillLevel(skill.getFactionSkillId());
				paramMap.put("factionSkillLevel", factionSkillLevel);
			}
			effectValue = ScriptService.getInstance().calcuFloat(sb.toString(), formula, paramMap, false);
		} catch (Exception ex) {
			StringBuilder sb = new StringBuilder();
			sb.append("battleSoldierId:").append(soldier.getId());
			sb.append(",formula:").append(formula);
			LogFactory.getLog("error.log").error(sb.toString(), ex);
		}
		return effectValue;
	}

	public static int skillEffect(CommandContext commandContext, BattleSoldier target, String formula, Map<String, Object> params) {
		int effectValue = 0;
		if (StringUtils.isBlank(formula))
			return effectValue;
		try {
			BattleSoldier trigger = commandContext.trigger();
			Map<String, Object> paramMap = new HashMap<>();
			paramMap.put("trigger", trigger);
			paramMap.put("skill", commandContext.skill());
			paramMap.put("target", target);
			paramMap.put("skillLevel", trigger.skillLevel(commandContext.skill().getId()));
			int factionSkillLevel = trigger.skillHolder().factionSkillLevel(commandContext.skill().getFactionSkillId());
			paramMap.put("factionSkillLevel", factionSkillLevel);
			float v = trigger.weaponAttack();
			paramMap.put("weaponAttack", v);
			paramMap.put("friendly", trigger.friendlyWith(target.getId()));
			if (params != null && !params.isEmpty())
				paramMap.putAll(params);
			paramMap.put("passSkillLevel", 0);
			int passSkillId = commandContext.skill().getRelativeSkillId();
			if (passSkillId != 0) {
				paramMap.put("passSkillLevel", trigger.skillLevel(passSkillId));
			}
			effectValue = ScriptService.getInstance().calcuInt("BattleUtils.skillEffect", formula, paramMap, true);
		} catch (Exception ex) {
			StringBuilder sb = new StringBuilder();
			sb.append("skillId:").append(commandContext.skill().getId());
			sb.append(",formula:").append(formula);
			LogFactory.getLog("error.log").error(sb.toString(), ex);
		}
		return effectValue;
	}

	public static float skillBuff(CommandContext commandContext, BattleSoldier target, String formula) {
		if (StringUtils.isBlank(formula)) {
			return 0;
		}
		try {
			Map<String, Object> paramMap = new HashMap<>();
			paramMap.put("trigger", commandContext.trigger());
			paramMap.put("target", target);
			paramMap.put("skillLevel", commandContext.trigger().skillLevel(commandContext.skill().getId()));
			return ScriptService.getInstance().calcuFloat("BattleUtils.skillBuff", formula, paramMap, true);
		} catch (Exception ex) {
			StringBuilder sb = new StringBuilder();
			sb.append("skillId:").append(commandContext.skill().getId());
			sb.append(",formula:").append(formula);
			LogFactory.getLog("error.log").error(sb.toString(), ex);
		}
		return 0;
	}

	public static float skillRate(BattleSoldier trigger, Skill skill, BattleSoldier target) {
		if (StringUtils.isBlank(skill.getSuccessRateFormula())) {
			return 0;
		}
		try {
			Map<String, Object> paramMap = new HashMap<>();
			paramMap.put("target", target);
			paramMap.put("skillLevel", trigger.skillLevel(skill.getId()));
			return ScriptService.getInstance().calcuFloat("BattleUtils.skillRate", skill.getSuccessRateFormula(), paramMap, true);
		} catch (Exception ex) {
			StringBuilder sb = new StringBuilder();
			sb.append("skillId:").append(skill.getId());
			sb.append(",formula:").append(skill.getSuccessRateFormula());
			LogFactory.getLog("error.log").error(sb.toString(), ex);
		}
		return 0;
	}

	public static float calculateBaseEffect(BattleBuffEntity buffEntity, BattleBuffContext targetBuffContext) {
		float effectValue = 0;
		String formula = targetBuffContext.battleBasePropertyEffectFormula();
		if (StringUtils.isBlank(formula)) {
			return effectValue;
		}
		int skillId = buffEntity.skillId();
		try {
			Map<String, Object> paramMap = new HashMap<>();

			BattleSoldier trigger = buffEntity.getTriggerSoldier();
			BattleSoldier target = buffEntity.getEffectSoldier();
			Map<String, Object> meta = buffEntity.getBattleMeta();
			int damage = Math.abs(buffEntity.hitDamageInput());
			paramMap.put("trigger", trigger);
			paramMap.put("target", target);
			paramMap.put("skillLevel", trigger.skillLevel(skillId));
			paramMap.put("buffPersistRound", buffEntity.getBuffPersistRound());
			paramMap.put("damage", damage);
			paramMap.put("spSpend", 0);
			if (meta.containsKey("buffAccAmount")) {
				int buffAccAmount = (Integer) meta.getOrDefault("buffAccAmount", 0);
				paramMap.put("buffAccAmount", buffAccAmount);
			}
			if (target.getCommandContext() != null) {
				int spSpend = target.getCommandContext().getSpSpent();
				paramMap.put("spSpend", spSpend);
			}
			effectValue = ScriptService.getInstance().calcuFloat("BattleUtils.calculateBaseEffect", formula, paramMap, true);
		} catch (Exception ex) {
			StringBuilder sb = new StringBuilder();
			sb.append("skillId:").append(skillId);
			sb.append("battleBuffId:").append(targetBuffContext.battleBuffId());
			sb.append(",formula:").append(formula);
			LogFactory.getLog("error.log").error(sb.toString(), ex);
		}
		return effectValue;
	}

	public static int randomActiveSkillId(SkillsWeight skillsWeight) {
		int curWeight = 0;
		int resultSkillId = 0;

		if (null == skillsWeight) {
			return resultSkillId;
		}

		List<SkillWeightInfo> skillWeightInfos = skillsWeight.skillWeightInfos();
		if (null == skillWeightInfos || skillWeightInfos.isEmpty()) {
			return resultSkillId;
		}

		int weightScope = skillsWeight.skillsWeightScope();
		if (weightScope < 1) {
			return resultSkillId;
		}

		int weightPivot = RandomUtils.nextInt(weightScope);
		for (int i = 0; i < skillWeightInfos.size(); i++) {
			SkillWeightInfo skillWeightInfo = skillWeightInfos.get(i);
			int curSkillId = skillWeightInfo.getSkillId();

			if (0 == curSkillId) {
				continue;
			}

			curWeight += skillWeightInfo.getSkillWeight();
			if (weightPivot <= curWeight) {
				resultSkillId = curSkillId;
				break;
			}
		}

		return resultSkillId;
	}

}
