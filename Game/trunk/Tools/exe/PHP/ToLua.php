<?php
$tTypeDef = array(
"bool"=>array("bool %s = (bool)luaL_checkinteger(pL, %d);", "lua_pushboolean(pL, %s);"),
"int8_t"=>array("int8_t %s = (int8_t)luaL_checkinteger(pL, %d);", "lua_pushinteger(pL, %s);"),
"int16_t"=>array("int16_t %s = (int16_t)luaL_checkinteger(pL, %d);", "lua_pushinteger(pL, %s);"),
"int32_t"=>array("int32_t %s = (int32_t)luaL_checkinteger(pL, %d);", "lua_pushinteger(pL, %s);"),
"int"=>array("int %s = (int)luaL_checkinteger(pL, %d);", "lua_pushinteger(pL, %s);"),
"int64_t"=>array("int64_t %s = (int64_t)luaL_checkinteger(pL, %d);", "lua_pushinteger(pL, %s);"),
"uin8_t"=>array("uint8_t %s = (uint8_t)luaL_checkinteger(pL, %d);", "lua_pushinteger(pL, %s);"),
"uint16_t"=>array("uint16_t %s = (uint16_t)luaL_checkinteger(pL, %d);", "lua_pushinteger(pL, %s);"),
"uint32_t"=>array("uint32_t %s = (uint32_t)luaL_checkinteger(pL, %d);", "lua_pushinteger(pL, %s);"),
"uint64_t"=>array("uint64_t %s = (uint64_t)luaL_checkinteger(pL, %d);", "lua_pushinteger(pL, %s);"),
"float"=>array("float %s = (float)luaL_checkinteger(pL, %d);", "lua_pushnumber(pL, %s);"),
"double"=>array("double %s = (double)luaL_checkinteger(pL, %d);", "lua_pushnumber(pL, %s);"),
"const char*"=>array("const char* %s = luaL_checkstring(pL, %d);", "lua_pushstring(pL, %s);"),
"void"=>array("", "lua_pushnil(pL);"),
);

$sToLuaDir = "F:\XProject\Src\ToLua";
$sOutCppFile = "F:\XProject\Src\ToLua\ServerToLua.cpp";
$sOutHeaderFile = "F:\XProject\Src\ToLua\ServerToLua.h";

$sLuaHeaderFmt = "public:\r\n\tstatic char className[];\r\n\tstatic Lunar<%s>::RegType methods[];\r\n";
$sLuaHeaderInitFmt = "char %s::className[] = \"%s\";\r\nLunar<%s>::RegType %s::methods[] =\r\n{%s\r\n\t{0,0}\r\n};";
$DIRECTORY_SEPARATOR = '/';

$sCont = iconv('GB2312', 'utf-8', "#ifndef __TOLUA_H__\r\n#define __TOLUA_H__\r\n#include \"LuaEngine/LuaEngine.h\"\r\n"); 
file_put_contents($sOutHeaderFile, $sCont);

$sCont = iconv('GB2312', 'utf-8', "#include \"ToLua/ServerToLua.h\"\r\n"); 
file_put_contents($sOutCppFile, $sCont);

$tRegClassList = array();
ProcDir($sToLuaDir);
function ProcDir($sToLuaDir)
{
	global $DIRECTORY_SEPARATOR, $sOutCppFile, $sOutHeaderFile, $tRegClassList; 
	
	if(is_dir($sToLuaDir))
	{
		$Handle = opendir($sToLuaDir);
		if (!$Handle)
		{
			exit("Open dir '$sToLuaDir' fail!\r\n");
		}

		while(($sFile = readdir($Handle)))
		{
			if($sFile == "." || $sFile == "..")
			{
				continue;
			}

			if(is_dir($sToLuaDir.$DIRECTORY_SEPARATOR.$sFile))
			{
				$sSubDir = $sToLuaDir.$DIRECTORY_SEPARATOR.$sFile;
				print("Ignor dir '$sSubDir'\r\n");
			}
			else
			{
				$sFile = $sToLuaDir.$DIRECTORY_SEPARATOR.$sFile;
				$nDot = strrpos($sFile, ".");
				if (!$nDot)
				{
					continue;
				}
				$sExt = substr($sFile, $nDot + 1, strlen($sFile) - $nDot);
				if (strtolower($sExt) == "tolua")
				{
					ToLua($sFile);
				}
				else
				{
					print("Ignor file '$sFile'\r\n");
				}
			}
		}
		closedir($Handle);
		
		$sFuncDecl = "\r\nvoid OpenServerToLua(); \r\n #endif";
		$sFuncImpl = "\r\nvoid OpenServerToLua()\r\n{";
		foreach ($tRegClassList as $k => $v)
		{
			$sFuncImpl .= "\r\n\t$v";
		}
		$sFuncImpl .= "\r\n}\r\n";
		
		$nFileHandle = fopen($sOutHeaderFile, "ab");
		$sUTF8FuncDecl = iconv('GB2312', 'utf-8', $sFuncDecl);
		fwrite($nFileHandle, $sUTF8FuncDecl);
		fclose($nFileHandle);
		
		$nFileHandle = fopen($sOutCppFile, "ab");
		$sUTF8FuncImpl = iconv('GB2312', 'utf-8', $sFuncImpl);
		fwrite($nFileHandle, $sUTF8FuncImpl);
		fclose($nFileHandle);
	}
	else
	{
		print("Dir '$sToLuaDir' is not a dir or not found!\r\n");
	}
}

function ToLua($sToLuaFile)
{
	global $sLuaHeaderFmt, $sLuaHeaderInitFmt, $tTypeDef, $sOutCppFile, $sOutHeaderFile, $tRegClassList;
	
	$sCont = file_get_contents($sToLuaFile);
	$tArray = explode("\r\n", $sCont);

	$bFullFunc = false;
	$sLuaClassDecl = "";
	$sLuaClassImpl = "";
	$sClassName = "";
	$sLuaClassName = "";
	$tFuncList = array();
	foreach($tArray as $k=>$v)
	{
		//class
		if (preg_match("/\s*#include.*/i", $v, $tMatchs))
		{
			$sLuaClassDecl .= $tMatchs[0]."\r\n";
		}
		else if (preg_match("/\s*class\s+?(\w+)/i", $v, $tMatchs))
		{
			$sClassName = $tMatchs[1];
			$sLuaClassName = "L".$tMatchs[1];
			$sLuaClassDecl .= "class ".$sLuaClassName." : public ".$sClassName."\r\n{\r\n";
			$sLuaHeader = sprintf($sLuaHeaderFmt, $sLuaClassName);
			$sLuaClassDecl .= $sLuaHeader."\r\npublic:";
			
			//construct
			$sLuaClassDecl .= "\r\n\t".$sLuaClassName."(lua_State* pL);";
			$sLuaClassImpl .= "\r\n".$sLuaClassName."::".$sLuaClassName."(lua_State* pL)\r\n{\r\n}";
		}
		//function
		elseif (preg_match("/\s*(\w+?)\s+(\S+?)\((.*?)\)/i", $v, $tMatchs))
		{
			$sReturnType = trim($tMatchs[1]);
			$sFuncName = trim($tMatchs[2]);
			$sParamList = trim($tMatchs[3]);
			print($sReturnType.":".$sFuncName.":".$sParamList."\r\n");
			//member function
			if ($tTypeDef[$sReturnType])
			{
				array_push($tFuncList, $sFuncName);
				$sLuaClassDecl .= "\r\n\r\n\tint ".$sFuncName."(lua_State* pL);";
				$sFuncImpl = "\r\n\r\nint ".$sLuaClassName."::".$sFuncName."(lua_State* pL)\r\n{\r\n\t";
				if (strpos($sParamList, "lua_State") !== false)
				{
					$sFuncImpl = "\r\n\r\nint ".$sLuaClassName."::".$sFuncName."($sParamList)\r\n";
					$sLuaClassImpl .= $sFuncImpl;
					$bFullFunc = true;
				}

				else
				{
					$bFullFunc = false;
					$tRealParams = array();
					if ($sParamList)
					{
						$tParams = explode(",", $sParamList);
						for ($i = 0; $i < count($tParams); $i++)
						{
							preg_match("/(.*)\s+\S+/i", $tParams[$i], $tParamInfo);
							$sParamType = trim($tParamInfo[1]);
							if ($tTypeDef[$sParamType])
							{
								$nParamIndex = $i + 1;
								$sParamName = "xVal".$i;
								$sFuncImpl .= sprintf($tTypeDef[$sParamType][0], $sParamName, $nParamIndex) ."\r\n\t";
								array_push($tRealParams, $sParamName);
							}
							else
							{
								exit("Param type '".$sType."' not support!\r\n");
							}
						}
					}
					$sParentFunc = $sClassName."::".$sFuncName."(";
					foreach($tRealParams as $k => $sParamName)
					{
						$sParentFunc .= $sParamName;
						if ($k != count($tRealParams) - 1)
						{
							$sParentFunc .= ",";
						}
					}
					$sParentFunc .= ")";
					$sFuncImpl .= sprintf($tTypeDef[$sReturnType][1], $sParentFunc)."\r\n\treturn 1;\r\n}";
					$sLuaClassImpl .= $sFuncImpl;
				}
			}
			else
			{
				exit("Return type '".$sReturnType."' not support!\r\n");
			}
		}
		//other
		else if ($bFullFunc)
		{
		 	if (preg_match("/}\s*;/i", $v))
		 	{
				$bFullFunc = false;
		 	}
		 	else
		 	{
				$sLuaClassImpl .= $v."\r\n";
		 	}
		}
		else if (preg_match("/REG_CLASS/i", $v))
		{
			array_push($tRegClassList, $v);
		}
	}
	if ($sLuaClassDecl != "" && $sLuaClassImpl != "")
	{
		$sLuaClassDecl .= "\r\n};\r\n";
		$sExportFuncList = "";
		foreach($tFuncList as $k => $v)
		{
			$sExportFuncList .= "\r\n\tLUNAR_DECLARE_METHOD(".$sLuaClassName.", ".$v."),";
		}
		$sLuaHeaderInit = sprintf($sLuaHeaderInitFmt, $sLuaClassName, $sLuaClassName, $sLuaClassName, $sLuaClassName, $sExportFuncList);
		$sLuaClassImpl .= "\r\n\r\n".$sLuaHeaderInit."\r\n\r\n";
		
		$nFileHandle = fopen($sOutCppFile, "ab");
		$sCont = iconv('GB2312', 'utf-8', $sLuaClassImpl);
		fwrite($nFileHandle, $sCont);
		fclose($nFileHandle);
		
		$nFileHandle = fopen($sOutHeaderFile, "ab"); "\r\n\t$v";
		$sCont = iconv('GB2312', 'utf-8', $sLuaClassDecl);
		fwrite($nFileHandle, $sCont);
		fclose($nFileHandle);
	}
}
?>