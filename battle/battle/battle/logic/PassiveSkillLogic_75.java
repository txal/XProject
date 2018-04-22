package com.nucleus.logic.core.modules.battle.logic;

import java.util.HashMap;
import java.util.Map;

import org.apache.commons.lang3.StringUtils;
import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.dto.VideoBuffAddTargetState;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;
import com.nucleus.player.service.ScriptService;

/**
 * 攻击前触发影响攻击力（不叠加）
 * 
 * @author hwy
 *
 */
@Service
public class PassiveSkillLogic_75 extends AbstractPassiveSkillLogic {

	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		if (config.getLaunchTiming() == timing.ordinal()) {
			int buffId = config.getSelfBuff();
			if (buffId > 0) {
				if (soldier.buffHolder().hasBuff(buffId))
					return false;
			}
		}
		return super.launchable(soldier, target, context, config, timing, passiveSkill);
	}

	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		float rate = context.getPerAttackVaryRate();
		if (config.getExtraParams() != null && config.getExtraParams().length > 0) {
			float addRate = Float.parseFloat(config.getExtraParams()[0]);
			context.setPerAttackVaryRate(rate + addRate);
		}
		int buffId = config.getSelfBuff();
		if (buffId > 0) {
			if (!soldier.buffHolder().hasBuff(buffId)) {
				BattleBuff buff = BattleBuff.get(buffId);
				if (buff != null) {
					int persistRound = calcPersistRound(soldier, buff);
					BattleBuffEntity buffEntity = new BattleBuffEntity(buff, soldier, soldier, 0, persistRound);
					if (soldier.buffHolder().addBuff(buffEntity)) {
						if (soldier.getCommandContext() != null)
							soldier.getCommandContext().skillAction().addTargetState(new VideoBuffAddTargetState(buffEntity));
					}
				}
			}
		}
	}

	private int calcPersistRound(BattleSoldier soldier, BattleBuff buff) {
		if (StringUtils.isBlank(buff.getBuffsPersistRoundFormula()))
			return 0;
		Map<String, Object> params = new HashMap<String, Object>();
		params.put("soldier", soldier);
		int v = ScriptService.getInstance().calcuInt("", buff.getBuffsPersistRoundFormula(), params, false);
		return v;
	}
}
