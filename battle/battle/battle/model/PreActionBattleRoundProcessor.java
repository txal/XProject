package com.nucleus.logic.core.modules.battle.model;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Iterator;
import java.util.List;

import com.nucleus.logic.core.modules.battle.data.Skill;

/**
 * 带前置执行动作的回合处理器:在正常回合行动之前先执行前置动作
 * 
 * @author wgy
 *
 */
public class PreActionBattleRoundProcessor extends DefaultBattleRoundProcessor {
	private final List<BattleSoldier> preActionQueue;
	private BattleSoldierSpeedComparator speedComparator;

	public PreActionBattleRoundProcessor(Battle battle) {
		super(battle);
		this.preActionQueue = new ArrayList<BattleSoldier>();
		this.speedComparator = new BattleSoldierSpeedComparator();
	}

	@Override
	protected void initRoundQueue() {
		if (!this.preActionQueue.isEmpty())
			this.preActionQueue.clear();
		this.preActionQueue.addAll(this.getBattle().battleInfo().preRoundActionQueue());
		super.initRoundQueue();
	}

	@Override
	protected void executePreActions() {
		if (preActionQueue.isEmpty())
			return;
		Collections.sort(preActionQueue, speedComparator);
		Iterator<BattleSoldier> it = preActionQueue.iterator();
		while (it.hasNext()) {
			BattleSoldier trigger = it.next();
			if (trigger != null && !trigger.isDead() && !trigger.isLeave()) {
				try {
					Skill skill = trigger.skillHolder().getPreRoundSkill();
					if (skill == null)
						continue;
					if (!preActionCheck(trigger))
						continue;
					int forceSkillId = trigger.forceSkillId();
					if (forceSkillId > 0) {//如果当前单位有强制执行技能,比如魔焰,则先去掉该技能,待回合前技能执行完之后再设置回去
						trigger.forceSkillId(0);
					}
					trigger.autoBattle(skill, null);
					trigger.actionStart();
					if (forceSkillId > 0) {
						trigger.forceSkillId(forceSkillId);
					}
				} catch (Exception e) {
					e.printStackTrace();
				}
			}
			it.remove();
		}
	}

	protected boolean preActionCheck(BattleSoldier trigger) {
		return true;
	}
}
