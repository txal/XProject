package com.nucleus.logic.core.modules.battle.logic;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.dto.VideoBuffAddTargetState;
import com.nucleus.logic.core.modules.battle.model.BattlePlayer;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff.BattleBasePropertyType;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffContext;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;
import com.nucleus.logic.core.modules.talent.model.PersistPlayerTalent;
import com.nucleus.player.service.ScriptService;

/**
 * 附加特殊buff
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLogic_22 extends AbstractPassiveSkillLogic {
	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		BattleBuffEntity buffEntity = null;
		if (config.getTargetBuff() > 0) {
			BattleBuff buff = BattleBuff.get(config.getTargetBuff());
			if (buff != null)
				buffEntity = doAddBuff(buff, soldier, target, context, config, passiveSkill.getId());
		}
		if (config.getSelfBuff() > 0) {
			BattleBuff buff = BattleBuff.get(config.getSelfBuff());
			if (buff != null)
				buffEntity = doAddBuff(buff, soldier, soldier, context, config, passiveSkill.getId());
		}
		if (buffEntity != null) {
			if (timing == PassiveSkillLaunchTimingEnum.TargetAddBuff && soldier.getCommandContext() != null)
				soldier.getCommandContext().skillAction().addTargetState(new VideoBuffAddTargetState(buffEntity));
			else if (timing == PassiveSkillLaunchTimingEnum.RoundStart) {
				soldier.currentVideoRound().readyAction().addTargetState(new VideoBuffAddTargetState(buffEntity));
			} else if (timing == PassiveSkillLaunchTimingEnum.RoundOver) {
				soldier.currentVideoRound().endAction().addTargetState(new VideoBuffAddTargetState(buffEntity));
			} else if (timing == PassiveSkillLaunchTimingEnum.UnderAttack || timing == PassiveSkillLaunchTimingEnum.TargetKilled || timing == PassiveSkillLaunchTimingEnum.BeforeCrit
					|| timing == PassiveSkillLaunchTimingEnum.AfterCrit || timing == PassiveSkillLaunchTimingEnum.TeammateDead || timing == PassiveSkillLaunchTimingEnum.SingleAttackEnd) {
				if (context != null)
					context.skillAction().addTargetState(new VideoBuffAddTargetState(buffEntity));
			}
			if (context != null && context.battle() != null) {
				List<BattleBuffEntity> addBuffs = new ArrayList<>(1);
				addBuffs.add(buffEntity);
				context.battle().onBuffAdd(context, soldier, target, addBuffs);
			}
		}
	}

	protected BattleBuffEntity doAddBuff(BattleBuff buff, BattleSoldier triggerSoldier, BattleSoldier effectSoldier, CommandContext context, PassiveSkillConfig config, int skillId) {
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
			String valueFormula = formula;
			int skillLevel = triggerSoldier.skillLevel(skillId);
			if (context != null) {
				Map<String, Object> params = new HashMap<String, Object>();
				params.put("damage", context.getDamageOutput());
				params.put("trigger", triggerSoldier);
				params.put("target", effectSoldier);
				params.put("skillLevel", skillLevel);
				params.put("talentPoint", 0);
				params.put("buffAccAmount", 0);
				BattlePlayer player = triggerSoldier.player();
				if (player != null) {
					PersistPlayerTalent talent = player.persistPlayer().persistVisitor().playerTalent();
					if (talent != null) {
						params.put("talentPoint", talent.totalTalentPoint() - talent.getTalentPoint());
					}
				}
				if (config.getExtraParams() != null && config.getExtraParams().length >= 2) {
					BattleBuffEntity battleBuffEntity = triggerSoldier.buffHolder().getBuff(Integer.parseInt(config.getExtraParams()[1]));
					if (battleBuffEntity != null) {
						params.put("buffAccAmount", battleBuffEntity.getBuffContexts().size());
					}
				}
				float v = ScriptService.getInstance().calcuFloat("", formula, params, false);
				valueFormula = String.valueOf(v);
			}
			BattleBuffContext buffContext = new BattleBuffContext(buff.getId(), BattleBasePropertyType.values()[property], valueFormula);
			List<BattleBuffContext> buffContextList = new ArrayList<BattleBuffContext>();
			buffContextList.add(buffContext);
			BattleBuffEntity buffEntity = new BattleBuffEntity(buff, triggerSoldier, effectSoldier, skillId, persistRound, buffContextList);
			if (effectSoldier.buffHolder().addBuff(buffEntity)) {
				return buffEntity;
			}
		}
		return null;
	}
}
