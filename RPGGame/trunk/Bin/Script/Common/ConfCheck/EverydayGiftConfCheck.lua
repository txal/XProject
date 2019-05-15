--每日礼包配置检查
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

local function _EverydayGiftConfCheck()
    for nID, tConf in pairs(ctRechargeConf)do
        if tConf.nType == 1 then        --1每日礼包充值
            assert(ctEverydayGiftConf[tConf.nMoney], "每日礼包配置错误，缺失充值金额为"..tConf.nMoney.."的配置")
        end
    end
end

_EverydayGiftConfCheck()