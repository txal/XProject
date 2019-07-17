local _rawget = rawget
local _assert = assert
local _insert = table.insert

local tClassDefineMt = {}
function tClassDefineMt.__index(tbl, key)
	local tBaseClass = tbl.__tbl_baseclass__
	for i = 1, #tBaseClass do
		local xValue = _rawget(tBaseClass[i], key)
		if xValue then
			--rawset(tbl, key, xValue) --这里会导致基类reload无效，但访问效率会提高，10w次相差10倍，为了稳定性牺牲效率
			return xValue
		end
	end
end
        
function class(...)
    local tArg = {...}
    local tClassDefine = {}
    --基本取/设函数
    tClassDefine.Get = function(self, field)
        local value = self[field]
        _assert(value ~= nil, "变量:"..field.."不能为nil,需要先定义")
        return value
    end
    tClassDefine.Set = function(self, field, value)
        _assert(self[field], "需要先定义变量:"..field)
        self[field] = value
    end

    --把所有的基类放到 tClassDefine.__tbl_bseclass__
    tClassDefine.__tbl_baseclass__ = {}
    for k= 1, #tArg do
    	local tBaseClass = tArg[k]
        _insert(tClassDefine.__tbl_baseclass__, tBaseClass)
        for j = 1, #tBaseClass.__tbl_baseclass__ do
        	_insert(tClassDefine.__tbl_baseclass__, tBaseClass.__tbl_baseclass__[j])
        end
    end

    --所有对实例对象的访问都会访问转到ClassDefine上
    local tInstanceMt =  { __index = tClassDefine }

    --IsClass函数提供对象是否某种类型的检测, 支持多重继承
    tClassDefine.IsClass = function(self, classtype)
        local bIsType = (self == classtype)
        if bIsType then
            return bIsType
        end
        for k = 1, #self.__tbl_baseclass__ do
            local baseclass = self.__tbl_baseclass__[k]
            bIsType =  (baseclass == classtype)
            if bIsType then
                return bIsType
            end
        end
        return bIsType
    end
    
    --构造函数参数的传递，只支持一层, 出于动态语言的特性以及性能的考虑
    tClassDefine.new = function(self, ...)
    	local tNewInstance = {}
        --IsType函数的支持由此来
    	tNewInstance.__classdefine__ = self
        tNewInstance.IsClass = function(self, classtype)
            return self.__classdefine__:IsClass(classtype)
        end
        --这里要放到调用构造函数之前,因为构造函数里面,可能调用基类的成员函数或者成员变量
        setmetatable(tNewInstance, tInstanceMt)
      	local fnCtor = _rawget(self, "Ctor")
        _assert(fnCtor, "构造函数未定义")
	    fnCtor(tNewInstance, ... )
    	return tNewInstance
    end

    setmetatable(tClassDefine, tClassDefineMt)
    return tClassDefine
end

