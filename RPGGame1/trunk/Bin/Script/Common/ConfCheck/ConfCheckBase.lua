

function ConfCheckBase:CheckItemExist(nItemType, nItemID)
    if nItemType == gtItemType.eProp then 
        return ctPropConf[nItemID] and true or false 
    elseif nItemType == gtItemType.eCurr then 
        return gtCurrName[nItemID] and true or false 
    elseif nItemType == gtItemType.ePet then 
        return ctPetInfoConf[nItemID] and true or false 
    elseif nItemType == gtItemType.ePartner then 
        return ctPartnerConf[nItemID] and true or false 
    elseif nItemType == gtItemType.eFaBao then 
        return ctFaBaoConf[nItemID] and true or false 
    elseif nItemType == gtItemType.eAppellation then 
        return ctAppellationConf[nItemID] and true or false 
    else
        return false
    end
end



