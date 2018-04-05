package com.nucleus.logic.core.modules.battle.logic;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.stereotype.Service;

import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.player.service.ScriptService;

/**
 * 对目标的队友中带有某些buff的进行溅射伤害
 *
 * @author wangyu
 */
@Service
public class PassiveSkillLogic_100 extends PassiveSkillLogic_93 {

	@Override
	protected int curDamage(BattleSoldier trigger, BattleSoldier target, CommandContext context, PassiveSkillConfig config, IPassiveSkill passiveSkill) {
		if (config.getExtraParams().length < 1)
			return 0;
		String formula = config.getExtraParams()[0];
		Map<String, Object> params = new HashMap<String, Object>();
		params.put("skillLevel", trigger.skillLevel(passiveSkill.getId()));
		float num = ScriptService.getInstance().calcuFloat("", formula, params, true);
		return (int) (num * context.getDamageOutput());
	}

	@Override
	protected List<BattleSoldier> seleTarget(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config) {
		List<BattleSoldier> seleTarget = new ArrayList<BattleSoldier>();
		if (config.getExtraParams() == null || config.getExtraParams().length < 2)
			return seleTarget;
		String buffIdStr = config.getExtraParams()[1];
		int[] buffIds = SplitUtils.split2IntArray(buffIdStr, "\\|");
		List<BattleSoldier> allAlive = target.team().aliveSoldiers();
		for (BattleSoldier battleSoldier : allAlive) {
			if (battleSoldier.getId() == target.getId()) {
				continue;
			}
			for (int buffId : buffIds) {
				if (battleSoldier.buffHolder().hasBuff(buffId)) {
					seleTarget.add(battleSoldier);
					break;
				}
			}
		}
		return seleTarget;
	}

}
