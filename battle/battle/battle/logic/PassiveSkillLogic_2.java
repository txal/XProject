package com.nucleus.logic.core.modules.battle.logic;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.apache.commons.lang3.ArrayUtils;
import org.apache.commons.lang3.StringUtils;
import org.springframework.stereotype.Service;

import com.nucleus.commons.data.StaticConfig;
import com.nucleus.commons.utils.RandomUtils;
import com.nucleus.logic.core.modules.AppStaticConfigs;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.model.BattlePlayer;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffContext;
import com.nucleus.logic.core.modules.talent.model.PersistPlayerTalent;
import com.nucleus.player.service.ScriptService;

/**
 * 伤害输出影响
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLogic_2 extends AbstractPassiveSkillLogic {
	protected String formula;

	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		if (context == null)
			return;
		int skillId = config.getRelativeSkillId() > 0 ? config.getRelativeSkillId() : passiveSkill.getId();
		int skillLevel = soldier.skillLevel(skillId);
		if (ArrayUtils.isNotEmpty(config.getPropertyEffectFormulas())) {
			String formula = StringUtils.isEmpty(this.formula) ? config.getPropertyEffectFormulas()[0] : this.formula;
			Map<String, Object> params = new HashMap<String, Object>();
			params.put("level", soldier.grade());
			params.put("skillLevel", skillLevel);
			params.put("damage", context.getDamageOutput());
			params.put("RandomUtils", RandomUtils.getInstance());
			params.put("self", soldier);
			params.put("roundBePhyAttackTimes", soldier.getRoundBePhyAttackTimes());
			params.put("roundBeMagicAttackTimes", soldier.getRoundBeMagicAttackTimes());
			int beAttackTime = soldier.getRoundBePhyAttackTimes() + soldier.getRoundBeMagicAttackTimes();
			params.put("roundBeAttackTimes", beAttackTime);
			params.put("target", target);
			params.put("critHurtRate", Math.max(1F, context.getCritHurtRate()));
			params.put("trigger", soldier);
			params.put("weaponAttack", soldier.weaponAttack());
			params.put("buffAccAmount", 0);
			params.put("talentPoint", 0);
			params.put("deadSp", soldier.deadSp());

			BattlePlayer player = soldier.player();
			if (player != null) {
				PersistPlayerTalent talent = player.persistPlayer().persistVisitor().playerTalent();
				if (talent != null) {
					params.put("talentPoint", talent.totalTalentPoint() - talent.getTalentPoint());
				}
			}
			// 根据敌方buff 叠加层数计算伤害值
			if (config.getExtraParams() != null && config.getExtraParams().length > 1) {
				int buffId = Integer.parseInt(config.getExtraParams()[1]);
				if (target.buffHolder().hasBuff(buffId)) {
					List<BattleBuffContext> contexts = target.buffHolder().getBuff(buffId).getBuffContexts();
					if (contexts != null) {
						int buffCount = contexts.size();
						params.put("buffAccAmount", buffCount);

					}
				}
			}

			Float damage = ScriptService.getInstance().calcuFloat("", formula, params, false);
			setDamage(context, damage.intValue());
			// 如果触发了浴血凤凰，会影响扣血下限，所以特殊处理
			if (skillId == StaticConfig.get(AppStaticConfigs.PHOENIX_BLOOD_SKILL).getAsInt(5322)) {
				soldier.setEffectPhoenixSkill(true);
			}
		}
		if (ArrayUtils.isNotEmpty(config.getExtraParams())) {
			try {
				float rate = Float.parseFloat(config.getExtraParams()[0]);
				context.setCurDamageVaryRate(rate);
			} catch (Exception e) {
				e.printStackTrace();
			}
		}

	}

	protected void setDamage(CommandContext context, int damage) {
		context.setDamageOutput(damage);
	}

}
