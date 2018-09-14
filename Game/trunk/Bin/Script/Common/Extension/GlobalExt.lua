gfRawToString = gfRawToString or tostring
function tostring(Val)
	if type(Val) == "table" then
		return gfRawToString(Val)..": "..table.ToString(Val, true)
	end
	return gfRawToString(Val)
end

gfRawPrint = gfRawPrint or print
print = CustomPrint

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

function gfReloadAll()
    for sModule, trunk in pairs(package.loaded) do
        if sModule ~= "protobuf.c" and sModule ~= "lpeg" then
            package.loaded[sModule] = nil
        end
    end
    return ReloadScript("Main")
end

----------cpp调用------------
function gfDebugPrint(n, ... )
    local tParam = table.pack(...)
    for k, v in ipairs( tParam ) do
        n = n[v]
    end
    CustomDebug(n) 
end
