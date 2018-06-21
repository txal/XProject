package com.nucleus.logic.core.modules.battle.logic;

import java.util.HashMap;
import java.util.Map;
import java.util.Set;

import org.springframework.stereotype.Service;

import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.dto.VideoActionTargetState;
import com.nucleus.logic.core.modules.battle.dto.VideoBuffAddTargetState;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;
import com.nucleus.player.service.ScriptService;

/**
 * 吸血(不限制可反击技能)
 * 
 * @author wangyu
 *
 */
@Service
public class PassiveSkillLogic_103 extends AbstractPassiveSkillLogic {

	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		if (!super.launchable(soldier, target, context, config, timing, passiveSkill))
			return false;
		return true;
	}

	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		int hp = calcValue(soldier, target, context, config, passiveSkill);
		hp = Math.abs(hp);
		soldier.increaseHp(hp);
		context.skillAction().addTargetState(new VideoActionTargetState(soldier, hp, 0, false));
		int skillId = config.getRelativeSkillId() > 0 ? config.getRelativeSkillId() : passiveSkill.getId();
		if (config.getExtraParams() != null && config.getExtraParams().length > 0) {
			Set<Integer> buffIds = SplitUtils.split2IntSet(config.getExtraParams()[0], ",");
			if (buffIds != null && !buffIds.isEmpty()) {
				// 目标是否有异常状态buff
				boolean targetHasBuff = false;
				for (int buffId : buffIds) {
					if (target.buffHolder().hasBuff(buffId)) {
						targetHasBuff = true;
						break;
					}
				}
				if (targetHasBuff && !soldier.antiPoison()) {
					BattleBuff buff = BattleBuff.get(config.getSelfBuff());
					BattleBuffEntity buffEntity = addBuff(soldier, soldier, skillId, buff);
					if (buffEntity != null)
						context.skillAction().addTargetState(new VideoBuffAddTargetState(buffEntity));
				}
			}
		}
	}

	private int calcValue(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, IPassiveSkill passiveSkill) {
		Map<String, Object> params = new HashMap<String, Object>();
		params.put("damage", context.getTotalHpVaryAmount());
		params.put("self", soldier);
		params.put("target", target);
		params.put("skillLevel", soldier.skillLevel(passiveSkill.getId()));
		int hp = ScriptService.getInstance().calcuInt("", config.getPropertyEffectFormulas()[0], params, false);
		return hp;
	}

}
