ctLogicFuncConf={}
ctLogicFuncConf[101]={nID=101,sDesc="恢复固定气血",sEffect="回复气血=%d",fnVal=function() return (0) end,tAttrAdd={{101,function() return (150) end,},},nClearBuffStateAttr=0,nBuffID=0,eRounds=function() return (0) end,}
ctLogicFuncConf[102]={nID=102,sDesc="恢复固定气血",sEffect="回复气血=%d",fnVal=function() return (0) end,tAttrAdd={{101,function() return (250) end,},},nClearBuffStateAttr=0,nBuffID=0,eRounds=function() return (0) end,}
ctLogicFuncConf[103]={nID=103,sDesc="恢复固定气血",sEffect="回复气血=%d",fnVal=function() return (0) end,tAttrAdd={{101,function() return (200) end,},},nClearBuffStateAttr=0,nBuffID=0,eRounds=function() return (0) end,}
ctLogicFuncConf[104]={nID=104,sDesc="恢复固定气血",sEffect="回复气血=%d",fnVal=function() return (0) end,tAttrAdd={{101,function() return (350) end,},},nClearBuffStateAttr=0,nBuffID=0,eRounds=function() return (0) end,}
ctLogicFuncConf[105]={nID=105,sDesc="恢复=品质*3+50气血，解除封类异常",sEffect="回复气血=%d，解除封印异常",fnVal=function() return (0) end,tAttrAdd={{101,function(star) return (star*3+50) end,},},nClearBuffStateAttr=2,nBuffID=0,eRounds=function() return (0) end,}
ctLogicFuncConf[106]={nID=106,sDesc="恢复=品质*4+50气血，解除属性建议类异常",sEffect="回复气血=%d，解除负面状态",fnVal=function() return (0) end,tAttrAdd={{101,function(star) return (star*4+50) end,},},nClearBuffStateAttr=5,nBuffID=0,eRounds=function() return (0) end,}
ctLogicFuncConf[107]={nID=107,sDesc="恢复=品质*10+500气血",sEffect="回复气血=%d",fnVal=function() return (0) end,tAttrAdd={{101,function(star) return (star*10+500) end,},},nClearBuffStateAttr=0,nBuffID=0,eRounds=function() return (0) end,}
ctLogicFuncConf[108]={nID=108,sDesc="恢复=品质*8+300气血",sEffect="回复气血=%d",fnVal=function() return (0) end,tAttrAdd={{101,function(star) return (star*8+300) end,},},nClearBuffStateAttr=0,nBuffID=0,eRounds=function() return (0) end,}
ctLogicFuncConf[109]={nID=109,sDesc="复活，恢复气血=品质*5+100",sEffect="复活，回复气血=%d",fnVal=function() return (0) end,tAttrAdd={{101,function(star) return (star*5+100) end,},},nClearBuffStateAttr=0,nBuffID=0,eRounds=function() return (0) end,}
ctLogicFuncConf[110]={nID=110,sDesc="复活，恢复气血=品质*3",sEffect="复活，回复气血=%d",fnVal=function() return (0) end,tAttrAdd={{101,function(star) return (star*3) end,},},nClearBuffStateAttr=0,nBuffID=0,eRounds=function() return (0) end,}
ctLogicFuncConf[111]={nID=111,sDesc="恢复气血=品质*9+400",sEffect="回复气血=%d",fnVal=function() return (0) end,tAttrAdd={{101,function(star) return (star*9+400) end,},},nClearBuffStateAttr=0,nBuffID=0,eRounds=function() return (0) end,}
ctLogicFuncConf[201]={nID=201,sDesc="恢复魔法=品质*2+20",sEffect="回复魔法=%d",fnVal=function() return (0) end,tAttrAdd={{102,function(star) return (star*2+20) end,},},nClearBuffStateAttr=0,nBuffID=0,eRounds=function() return (0) end,}
ctLogicFuncConf[202]={nID=202,sDesc="恢复魔法=品质*3+20",sEffect="回复魔法=%d",fnVal=function() return (0) end,tAttrAdd={{102,function(star) return (star*3+20) end,},},nClearBuffStateAttr=0,nBuffID=0,eRounds=function() return (0) end,}
ctLogicFuncConf[203]={nID=203,sDesc="恢复魔法=品质*4+20",sEffect="回复魔法=%d",fnVal=function() return (0) end,tAttrAdd={{102,function(star) return (star*4+20) end,},},nClearBuffStateAttr=0,nBuffID=0,eRounds=function() return (0) end,}
ctLogicFuncConf[204]={nID=204,sDesc="恢复魔法=品质*人物等级*0.15+人物等级*5+50",sEffect="回复魔法=%d",fnVal=function() return (0) end,tAttrAdd={{102,function(star,rolelv) return (star*rolelv*0.15+rolelv*5+50) end,},},nClearBuffStateAttr=0,nBuffID=0,eRounds=function() return (0) end,}
ctLogicFuncConf[205]={nID=205,sDesc="恢复魔法=品质*人物等级*0.1+人物等级*8+50",sEffect="回复魔法=%d",fnVal=function() return (0) end,tAttrAdd={{102,function(star,rolelv) return (star*rolelv*0.1+rolelv*8+50) end,},},nClearBuffStateAttr=0,nBuffID=0,eRounds=function() return (0) end,}
ctLogicFuncConf[301]={nID=301,sDesc="增加SP=星级*10",sEffect="增加怒气=%d,获得3回合混乱状态",fnVal=function() return (0) end,tAttrAdd={{103,function(star) return (star*10) end,},},nClearBuffStateAttr=0,nBuffID=402,eRounds=function() return (3) end,}
ctLogicFuncConf[302]={nID=302,sDesc="增加SP=星级*5+10",sEffect="增加怒气=%d",fnVal=function() return (0) end,tAttrAdd={{103,function(star) return (star*5+10) end,},},nClearBuffStateAttr=0,nBuffID=0,eRounds=function() return (0) end,}
ctLogicFuncConf[303]={nID=303,sDesc="增加SP=星级*10,防御降低=星级*15",sEffect="增加怒气=%d，降低防御=%d",fnVal=function() return (0) end,tAttrAdd={{103,function(star) return (star*10) end,},{105,function(star) return (-star*15) end,},},nClearBuffStateAttr=0,nBuffID=0,eRounds=function() return (0) end,}
ctLogicFuncConf[304]={nID=304,sDesc="增加SP=星级*10",sEffect="增加怒气=%d,获得3回合混睡眠状态",fnVal=function() return (0) end,tAttrAdd={{103,function(star) return (star*10) end,},},nClearBuffStateAttr=0,nBuffID=401,eRounds=function() return (3) end,}
ctLogicFuncConf[401]={nID=401,sDesc="增加双倍点数",sEffect="增加双倍点=%d",fnVal=function() return (50) end,tAttrAdd={{0,function() return (0) end,},},nClearBuffStateAttr=0,nBuffID=0,eRounds=function() return (0) end,}