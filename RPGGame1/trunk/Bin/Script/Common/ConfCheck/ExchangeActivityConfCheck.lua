--兑换活动配置预处理
local _ctExchangeConf = {}
local function _ExchangeActivityConfCheck()
    for _, tConf in pairs(ctExchangeActivityConf) do
        _ctExchangeConf[tConf.nActivityID] = _ctExchangeConf[tConf.nActivityID] or {}

        assert(tConf.nMaxTimes >= 0, "兑换配置有错，ID："..tConf.nActivityID)
        for _, tStuff in pairs(tConf.tStuffList) do
           assert(ctPropConf[tStuff[1]], "兑换配置有错，ID："..tConf.nActivityID) 
        end
        
        for _, tItem in pairs(tConf.tItemList) do
            assert(ctPropConf[tItem[1]], "兑换配置有错，ID："..tConf.nActivityID)
        end

        _ctExchangeConf[tConf.nActivityID][tConf.nExchangeID] = tConf        
    end
end
_ExchangeActivityConfCheck()

function ctExchangeActivityConf.GetConf(nActivityID, nExchangeID)
    return _ctExchangeConf[nActivityID][nExchangeID]
end

function ctExchangeActivityConf.GetActConf(nActivityID)
    return _ctExchangeConf[nActivityID]
end