gfRawToString = gfRawToString or tostring
function tostring(Val)
	if type(Val) == "table" then
		return table.ToString(Val, true)
	end
	return gfRawToString(Val)
end

gfRawPrint = gfRawPrint or print
print = gbDebug and CustomPrint or function() end

gfRawError = gfRawError or error
error = CustomError

function gfReloadScript(sScript, sProject)
    assert(sScript ~= "")
    local sModule = sScript
    if (sProject or "") ~= "" then
        sModule = sProject.."/"..sModule
    end
    package.loaded[sModule] = nil  
    return ReloadScript(sScript)
end

function gfReloadAll(sProject)
    for sModule, trunk in pairs(package.loaded) do
        if sModule ~= "protobuf.c" and sModule ~= "lpeg" then
            package.loaded[sModule] = nil
        end
    end
    local sMain = "Main"
    if (sProject or "") ~= "" then
        sMain = sProject.."/"..sMain
    end
    local bRes = ReloadScript(sMain)
    collectgarbage()
    return bRes
end

----------cpp调用------------
function gfDebugPrint(data)
    CustomDebug(data) 
end
