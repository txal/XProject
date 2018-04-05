package com.nucleus.logic.core.modules.battle.logic;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.dto.VideoBuffAddTargetState;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff.BattleBasePropertyType;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffContext;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;
import com.nucleus.player.service.ScriptService;

/**
 * 给主角加buff
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLogic_41 extends AbstractPassiveSkillLogic {
	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		BattleBuff buff = BattleBuff.get(config.getTargetBuff());
		if (buff != null) {
			if (soldier.playerId() <= 0)
				return;
			BattleSoldier mainCharactor = soldier.battle().battleInfo().battleSoldier(soldier.playerId());
			if (mainCharactor == null)
				return;
			if (config.getPropertys() != null && config.getPropertyEffectFormulas() != null) {
				int property = config.getPropertys()[0];
				String formula = config.getPropertyEffectFormulas()[0];
				int persistRound = 0;
				try {
					if (config.getExtraParams() != null)
						persistRound = Integer.parseInt(config.getExtraParams()[0]);
				} catch (Exception e) {
					e.printStackTrace();
				}
				Map<String, Object> params = new HashMap<String, Object>();
				params.put("lv", soldier.grade());
				float v = ScriptService.getInstance().calcuFloat("", formula, params, false);
				BattleBuffContext buffContext = new BattleBuffContext(buff.getId(), BattleBasePropertyType.values()[property], String.valueOf(v));
				List<BattleBuffContext> buffContextList = new ArrayList<BattleBuffContext>();
				buffContextList.add(buffContext);
				BattleBuffEntity buffEntity = new BattleBuffEntity(buff, soldier, mainCharactor, passiveSkill.getId(), persistRound, buffContextList);
				if (mainCharactor.buffHolder().addBuff(buffEntity))
					context.skillAction().addTargetState(new VideoBuffAddTargetState(buffEntity));
			}
		}
	}
}
