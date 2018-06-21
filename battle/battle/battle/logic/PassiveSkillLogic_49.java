package com.nucleus.logic.core.modules.battle.logic;

import java.util.ArrayList;
import java.util.List;
import java.util.Set;

import org.springframework.stereotype.Service;

import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.dto.VideoBuffAddTargetState;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff.BattleBasePropertyType;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffContext;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;

/**
 * 鼓舞：给指定目标叠加buff,有100%上限
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLogic_49 extends AbstractPassiveSkillLogic {
	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		if (config.getExtraParams() == null || config.getExtraParams().length <= 0)
			return;
		int buffId = config.getTargetBuff();
		if (buffId <= 0)
			return;
		BattleBuff buff = BattleBuff.get(buffId);
		if (buff == null)
			return;
		Set<Integer> monsterIds = SplitUtils.split2IntSet(config.getExtraParams()[0], ",");
		int limit = Integer.parseInt(config.getExtraParams()[1]);
		for (int monsterId : monsterIds) {
			if (monsterId <= 0)
				continue;
			for (BattleSoldier s : soldier.team().aliveSoldiers()) {
				if (s.getId() != soldier.getId() && monsterId == s.monsterId()) {
					BattleBuffEntity buffEntity = overlayBuff(s, buff, limit, passiveSkill.getId());
					if (buffEntity != null) {
						if (context != null)
							context.skillAction().addTargetState(new VideoBuffAddTargetState(buffEntity));
						else
							soldier.currentVideoRound().endAction().addTargetState(new VideoBuffAddTargetState(buffEntity));
					}
				}
			}
		}
	}

	private BattleBuffEntity overlayBuff(BattleSoldier soldier, BattleBuff buff, int limit, int skillId) {
		BattleBuffEntity buffEntity = soldier.buffHolder().getBuff(buff.getId());
		if (buffEntity != null) {
			if (buffEntity.getBuffContexts().size() >= limit) {
				return null;
			} else {
				int property = buff.getBattleBasePropertyTypes()[0];
				String formula = buff.getBattleBasePropertyEffectFormulas()[0];
				buffEntity.getBuffContexts().add(new BattleBuffContext(buff.getId(), BattleBasePropertyType.values()[property], formula));
			}
		} else {
			buffEntity = addBuff(soldier, soldier, skillId, buff);
		}
		return buffEntity;
	}

	@Override
	protected BattleBuffEntity addBuff(BattleSoldier triggerSoldier, BattleSoldier effectSoldier, int skillId, BattleBuff buff) {
		int persistRound = Integer.parseInt(buff.getBuffsPersistRoundFormula());
		if (persistRound > 0) {
			int property = buff.getBattleBasePropertyTypes()[0];
			String formula = buff.getBattleBasePropertyEffectFormulas()[0];
			BattleBuffContext buffContext = new BattleBuffContext(buff.getId(), BattleBasePropertyType.values()[property], formula);
			List<BattleBuffContext> buffContextList = new ArrayList<BattleBuffContext>();
			buffContextList.add(buffContext);

			BattleBuffEntity buffEntity = new BattleBuffEntity(buff, triggerSoldier, effectSoldier, skillId, persistRound, buffContextList);
			if (effectSoldier.buffHolder().addBuff(buffEntity))
				return buffEntity;
		}
		return null;
	}
}
