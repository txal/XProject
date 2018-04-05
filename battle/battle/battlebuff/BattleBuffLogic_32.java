/**
 * 
 */
package com.nucleus.logic.core.modules.battlebuff;

import java.util.Map;

import org.springframework.stereotype.Service;

import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff;
import com.nucleus.logic.core.modules.battlebuff.model.BuffLogicParam;
import com.nucleus.logic.core.modules.battlebuff.model.BuffLogicParam_32;

/**
 * 给对方附加buff
 * 
 * @author hwy
 *
 */
@Service
public class BattleBuffLogic_32 extends BattleBuffLogicAdapter {

	@Override
	protected BuffLogicParam newParam() {
		return new BuffLogicParam_32();
	}

	@Override
	public void doInitParam(BattleBuff buff, String paramStr) {
		Map<String, String> properties = SplitUtils.split2StringMap(paramStr, ",", ":");
		BuffLogicParam_32 param = (BuffLogicParam_32) buff.getBuffParam();
		param.setBuffIds((SplitUtils.split2IntSet(properties.get("buffIds"), "\\|")));
	}

}
