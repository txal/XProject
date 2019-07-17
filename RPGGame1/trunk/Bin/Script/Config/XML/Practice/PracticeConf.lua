ctPracticeConf={}
ctPracticeConf[101]={nID=101,sName="攻法修炼",nIcon=2011,fnNeedExp=function(LV) return (LV^3*10+(LV-1)*100+200) end,tBaseProperty={{108,2,5,},{208,2,5,},{204,2,0,},},sDes="每级可使人物的物理、法术伤害结果增加2%+5点；提高2%封印成功率",nPos=1,}
ctPracticeConf[102]={nID=102,sName="防御修炼",nIcon=2012,fnNeedExp=function(LV) return (LV^3*5+(LV-1)*50+100) end,tBaseProperty={{109,2,5,},},sDes="每级可使人物受到的物理伤害结果减少2%+5点",nPos=2,}
ctPracticeConf[103]={nID=103,sName="法抗修炼",nIcon=2013,fnNeedExp=function(LV) return (LV^3*5+(LV-1)*50+100) end,tBaseProperty={{209,2,5,},{205,2,0,},},sDes="每级可使人物受到的法术伤害结果减少2%+5点；提高2%抗封率",nPos=3,}
ctPracticeConf[201]={nID=201,sName="攻法指挥",nIcon=2014,fnNeedExp=function(LV) return (LV^3*10+(LV-1)*100+200) end,tBaseProperty={{108,2,5,},{208,2,5,},{204,2,0,},},sDes="每级可使伙伴的物理、法术伤害结果增加2%+5点；提高2%封印成功率",nPos=4,}
ctPracticeConf[202]={nID=202,sName="防御指挥",nIcon=2015,fnNeedExp=function(LV) return (LV^3*5+(LV-1)*50+100) end,tBaseProperty={{109,2,5,},},sDes="每级可使伙伴受到的物理伤害结果减少2%+5点",nPos=5,}
ctPracticeConf[203]={nID=203,sName="法抗指挥",nIcon=2016,fnNeedExp=function(LV) return (LV^3*5+(LV-1)*50+100) end,tBaseProperty={{209,2,5,},{205,2,0,},},sDes="每级可使伙伴受到的法术伤害结果减少2%+5点；提高2%抗封率",nPos=6,}
ctPracticeConf[301]={nID=301,sName="宠物攻法",nIcon=2017,fnNeedExp=function(LV) return (LV^3*10+(LV-1)*100+200) end,tBaseProperty={{108,2,5,},{208,2,5,},},sDes="每级可使宠物的物理、法术伤害结果增加2%+5点",nPos=7,}
ctPracticeConf[302]={nID=302,sName="宠物防御",nIcon=2018,fnNeedExp=function(LV) return (LV^3*10+(LV-1)*100+200) end,tBaseProperty={{109,2,5,},{209,2,5,},},sDes="每级可使宠物受到的物理、法术伤害结果减少2%+5点",nPos=8,}
