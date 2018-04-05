/**
 * 
 */
package com.nucleus.logic.core.modules.battle.logic;

import com.nucleus.commons.data.StaticConfig;
import com.nucleus.logic.core.modules.AppStaticConfigs;
import com.nucleus.logic.core.modules.assistskill.data.ScenarioSkill;
import com.nucleus.logic.core.modules.assistskill.model.PersistPlayerScenarioSkill;
import com.nucleus.logic.core.modules.assistskill.model.ScenarioSkillInfo;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.dto.VideoActionTargetState;
import com.nucleus.logic.core.modules.battle.dto.VideoSoldier.SoldierStatus;
import com.nucleus.logic.core.modules.battle.model.BattlePlayer;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.player.service.ScriptService;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;

/**
 * 防御/保护
 * 
 * @author liguo
 * 
 */
@Service
public class SkillLogic_4 extends SkillLogicAdapter {

	@Override
	public void doFired(CommandContext commandContext) {
		BattleSoldier trigger = commandContext.trigger();
		Skill skill = commandContext.skill();
		trigger.initForceSkill(skill.getSelfNextRoundForceSkillId());

		BattleSoldier target = commandContext.target();
		if (target == null) {
			int defenseSkillId = StaticConfig.get(AppStaticConfigs.DEFAULT_DEFENSE_SKILL_ID).getAsInt(2);
			if (skill.getId() == defenseSkillId) {// 防御技能直接设置目标为自己
				target = trigger;
			}
		}
		if (target.isDead()) {
			return;
		}
		int mp = 0;
		if (trigger.getId() == target.getId()) {
			trigger.updateSoldierStatus(SoldierStatus.SelfDefense);
			// 剧情技能逻辑：防御时恢复mp
			mp = scenarioSkillEffect(trigger, commandContext);
		} else {
			target.addProtectedBySoldierId(trigger.getId());
		}

		commandContext.skillAction().addTargetState(new VideoActionTargetState(target, 0, mp, false));
	}

	private int scenarioSkillEffect(BattleSoldier trigger, CommandContext commandContext) {
		if (!trigger.ifMainCharactor())
			return 0;
		BattlePlayer player = trigger.player();
		if (player == null)
			return 0;
		PersistPlayerScenarioSkill pps = player.persistPlayerScenarioSkill();
		ScenarioSkill ss = ScenarioSkill.get(ScenarioSkill.SCENARIO_SKILL_ID_3);
		if (ss == null)
			return 0;
		ScenarioSkillInfo skillInfo = pps.scenarioSkillMap().get(ss.getId());
		if (skillInfo == null || skillInfo.getLevel() <= 0)
			return 0;
		Map<String, Object> params = new HashMap<String, Object>();
		params.put("skillLevel", skillInfo.getLevel());
		params.put("grade", player.getGrade());
		int mp = ScriptService.getInstance().calcuInt("", ss.getEffectFormula(), params, false);
		trigger.increaseMp(commandContext, mp);
		return mp;
	}

}
