package com.nucleus.logic.core.modules.battle.logic;

import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.dto.VideoActionTargetState;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battle.model.RoundContext.RoundState;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff.BattleBasePropertyType;
import com.nucleus.player.service.ScriptService;

/**
 * 自己死亡情况下,恢复己方血量最低的玩家(除自己)mp/hp/sp
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLogic_70 extends AbstractPassiveSkillLogic {
	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		boolean launchable = super.launchable(soldier, target, context, config, timing, passiveSkill);
		if (!launchable)
			return false;
		return soldier.isDead();
	}

	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		if (config.getPropertys() != null && config.getPropertyEffectFormulas() != null && config.getPropertys().length == config.getPropertyEffectFormulas().length) {
			BattleSoldier restoreSoldier = findTarget(soldier);
			if (restoreSoldier == null)
				return;
			int hp = 0, mp = 0, sp = 0;
			for (int i = 0; i < config.getPropertys().length; i++) {
				int property = config.getPropertys()[i];
				int skillLevel = soldier.skillLevel(passiveSkill.getId());
				int value = (int) calcLevelValue(restoreSoldier, config.getPropertyEffectFormulas()[i], context, skillLevel);
				if (property == BattleBasePropertyType.Hp.ordinal()) {
					hp = value;
					if (hp > 0)
						restoreSoldier.increaseHp(hp);
					else if (hp < 0)
						restoreSoldier.decreaseHp(hp);
				} else if (property == BattleBasePropertyType.Mp.ordinal()) {
					mp = value;
					if (mp > 0)
						restoreSoldier.increaseMp(mp);
					else if (mp < 0)
						restoreSoldier.decreaseMp(mp);
				} else if (property == BattleBasePropertyType.Sp.ordinal()) {
					sp = value;
					if (sp > 0)
						restoreSoldier.increaseSp(sp);
					else if (sp < 0)
						restoreSoldier.decreaseSp(sp);
				}
			}
			VideoActionTargetState state = new VideoActionTargetState(restoreSoldier, hp, mp, false, sp);
			if (context != null)
				context.skillAction().addTargetState(state);
			else if (soldier.roundContext().getState() == RoundState.RoundStart)
				restoreSoldier.currentVideoRound().readyAction().addTargetState(state);
			else if (soldier.roundContext().getState() == RoundState.RoundOver)
				restoreSoldier.currentVideoRound().endAction().addTargetState(state);
		}
	}

	private BattleSoldier findTarget(BattleSoldier soldier) {
		Optional<BattleSoldier> opt = soldier.team().aliveSoldiers().stream().filter(s -> s.isMainCharactor()).sorted((s1, s2) -> s1.hp() - s2.hp()).findFirst();
		return opt.isPresent() ? opt.get() : null;
	}

	private float calcLevelValue(BattleSoldier soldier, String formula, CommandContext context, int skillLevel) {
		Map<String, Object> params = new HashMap<String, Object>();
		params.put("target", soldier);
		params.put("skillLevel", skillLevel);
		return ScriptService.getInstance().calcuFloat("", formula, params, false);
	}
}
