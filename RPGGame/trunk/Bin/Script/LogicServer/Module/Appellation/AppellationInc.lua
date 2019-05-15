
CAppellationBase = CAppellationBase or class()
CAppellationArena =CAppellationArena or class(CAppellationBase)
CAppellationPVPAct = CAppellationPVPAct or class(CAppellationBase)
CAppellationRelation = CAppellationRelation or class(CAppellationBase)
CAppellationRank = CAppellationRank or class(CAppellationBase)
CAppellationUnionPos = CAppellationUnionPos or class(CAppellationBase)
CAppellationPVEAct = CAppellationPVEAct or class(CAppellationBase)

CAppellationBox = CAppellationBox or class(CModuleBase)



require("Module/Appellation/AppellationDef")
require("Module/Appellation/AppellationBase")
require("Module/Appellation/AppellationArena")
require("Module/Appellation/AppellationPVPAct")
require("Module/Appellation/AppellationRelation")
require("Module/Appellation/AppellationRank")
require("Module/Appellation/AppellationUnionPos")
require("Module/Appellation/AppellationPVEAct")

require("Module/Appellation/AppellationBox")
require("Module/Appellation/AppellationRpc")

