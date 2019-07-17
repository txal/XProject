<?php
//i 整形
//s 字符串
//t 表

error_reporting(E_ALL);

if (count($argv) < 3)
{
	exit("ERROR: Please set the csv file dir and lua file dir");
}

$sCSVDir = $argv[1];
$sScriptDir = $argv[2];

if(!is_dir($sCSVDir))
{
	exit("ERROR: Dir '$sCSVDir' is not found!");
}

if(!is_dir($sScriptDir))
{
	exit("ERROR: Dir '$sScriptDir' is not found!");
}

$DIRECTORY_SEPARATOR = '/';
$tLuaFileList = array();

ProcDir($sCSVDir, $sScriptDir);

function ProcDir($sCSVDir, $sScriptDir)
{
	global $DIRECTORY_SEPARATOR;

	if(is_dir($sCSVDir))
	{
		$Handle = opendir($sCSVDir);
		if (!$Handle)
		{
			exit();
		}

		while(($sFile = readdir($Handle)))
		{
			if($sFile == "." || $sFile == "..")
			{
				continue;
			}

			if(is_dir($sCSVDir.$DIRECTORY_SEPARATOR.$sFile))
			{
				$sSubCSVDir = $sCSVDir.$DIRECTORY_SEPARATOR.$sFile; 
				$sSubScriptDir = $sScriptDir.$DIRECTORY_SEPARATOR.$sFile;
				@mkdir($sSubScriptDir, 0777);
				ProcDir($sSubCSVDir, $sSubScriptDir);
			}
			else
			{
				$sCSVFile = $sCSVDir.$DIRECTORY_SEPARATOR.$sFile;
				$nDot = strrpos($sCSVFile, ".");
				if (!$nDot) continue;
				$sExt = substr($sCSVFile, $nDot + 1, strlen($sCSVFile) - $nDot);
				if (strtolower($sExt) == "csv")
					CSV2Lua($sCSVFile, $sScriptDir);
			}
		}
		closedir($Handle);
	}
	else
	{
		print("ERROR: Dir '$sDir' is not a dir or not found!\n");
	}
}

function CSV2Lua($sCSVFile, $sScriptDir)
{
	global $tLuaFileList;
	global $DIRECTORY_SEPARATOR; 

	$sPrefix = "ct";

	$hFile = fopen($sCSVFile, "r");  
	if (!$hFile)
	{
		exit();
	}
	$nDs = strrpos($sCSVFile, $DIRECTORY_SEPARATOR);
	if (!$nDs) 
	{
		print("ERROR: '$sCSVFile' extract name fail!");
		return;
	}
	$nDot = strrpos($sCSVFile, ".");
	$sFileName = substr($sCSVFile, $nDs + 1, $nDot - $nDs - 1);
	$sLuaFile = $sScriptDir.$DIRECTORY_SEPARATOR.$sFileName.".lua";

	print("Converting: ${sFileName}.csv => ${sFileName}.lua\n");

	$sRootTable = $sPrefix.$sFileName;
	$sScript = "$sRootTable={}\n";
	array_push($tLuaFileList, array($sRootTable, $sLuaFile));

	$nRow = 0;
	$tType = array();
	$tField = array();
	$tFieldSpec = array();
	$bNotHasFieldSpec = false;

	$keywords = array("min", "max", "math", "floor", "ceil", "abs", "pow", "and", "or", "random");
	while ($tRow=fgetcsv($hFile))
	{
		$nRow++;
		$sRowScript = "";
		if ($nRow == 1)
		{
			//注释行
		}
		else if ($nRow == 2)
		{
			if (strlen($tRow[0]) == 1 && is_numeric($tRow[0]))
			{
				$tFieldSpec = $tRow;
				$bNotHasFieldSpec = false;	
			}
			else
			{

				$bNotHasFieldSpec = true;	
				foreach ($tRow as $key => $value)
				{
					$tFieldSpec[$key] = $value;
				}
				//字段行
				$tField = $tRow;
			}
		}
		else if ($nRow == 3)
		{	
			if ($bNotHasFieldSpec)
			{
				//类型行
				$tType = $tRow;
			}
			else
			{
				$tField = $tRow;
			}
		}
		else if ($nRow == 4)
		{
			if ($bNotHasFieldSpec)
			{//注释行

			}
			else
			{
				$tType = $tRow;
			}
		}
		else if (!$bNotHasFieldSpec && $nRow == 5)
		{//注释行
		}
		else if ($nRow >= 5)
		{
			if ($tFieldSpec[0] == "2") 
			{
				continue;	
			}

			$sValue = $tRow[0];
			if (is_numeric($sValue))
			{
				$key = floatval($sValue);
			}
			else
			{
				$key = "\"$sValue\"";
			}

			$sSubTable = $sRootTable."[$key]";
			$sRowScript = "$sSubTable={";
			$nValidColumn = 0;
			foreach ($tRow as $k => $v)
			{
				if ($tFieldSpec[$k] == "2")
				{
					continue;
				}
				$nValidColumn++;
				$nCol = $k;
				$sValue = $v;
				switch(substr($tType[$nCol],0,1))
				{
					case "i":
					{
						if (!is_numeric($sValue))
						{
							exit("ERROR: Row:$nRow Col:$tField[$nCol] value error!\n");
						}
						$sValue = $sValue;
						$sRowScript .= "$tField[$nCol]=$sValue,";
						break;
					}
					case "b":
					{
						$iValue = intVal($sValue);
						$sValue = $iValue != 0 ? "true" : "false";
						$sRowScript .= "$tField[$nCol]=$sValue,";
						break;
					}
					case "s":
					{
						$sValue = "\"".strVal($sValue)."\"";
						$sRowScript .= "$tField[$nCol]=$sValue,";
						break;
					}
					case "e":
					{
						$params = array();
						$sValue = str_replace("?", " and ", $sValue);
						$sValue = str_replace(":", " or ", $sValue);
						$sValue = str_ireplace("Math", "math", $sValue);
						preg_match_all("/[a-zA-Z]+/i", strVal($sValue), $params);
						if (count($params[0]) > 0)
						{
							$params[0] = array_unique($params[0]);
							$params[0] = array_diff($params[0], $keywords);
							$sValue = "function(".join(",",$params[0]).") return ($sValue) end";
						}
						else
							$sValue = "function() return ($sValue) end";
						$sRowScript .= "$tField[$nCol]=$sValue,";
						break;
					}
					case "c":
					{
						$sValue = strVal($sValue);
						$sRowScript .= "$tField[$nCol]=$sValue,";
						break;
					}
					case "t":
					{
						$sType = $tType[$nCol];
						$nTableLevel = substr_count($sType, "t");
						if ($nTableLevel == 0)
						{
							exit("ERROR: '$sType' not support!\n");
						}
						if ($nTableLevel >= 2)
						{
							exit("ERROR: '$sType' error, only support 1 levels table, break!\n");
						}
						$sType = substr($sType, 2, -1);
						$sRowScript .= "$tField[$nCol]={";
						$tSubTable = explode(";", $sValue);
						foreach ($tSubTable as $k => $v)
						{
							if ($v == "")
							{
								break;
							}
							$sRowScript .= "{";
							$tMember = explode(",", $v);
							for ($i = 0; $i < strlen($sType); $i++)
							{
								if (!isset($tMember[$i]))
								{
									exit("ERROR: Row:$nRow Col:$tField[$nCol] is empty!\n");
								}
								switch ($sType[$i])
								{
									case "i":
									{
										$nVal = $tMember[$i];
										if (!is_numeric($nVal))
										{
											exit("ERROR: Row:$nRow Col:$tField[$nCol] value error!\n");
										}	
										$sRowScript .= "$nVal,";
										break;
									}
									case "b":
									{
										$iValue = intVal($tMember[$i]);
										$sValue = $iValue != 0 ? "true" : "false";	
										$sRowScript .= "$sValue,";
										break;
									}
									case "s":
									{
										$sVal = "\"".strval($tMember[$i])."\"";
										$sRowScript .= "$sVal,";
										break;
									}
									case "e":
									{
										$data = "";
										if ($i == strlen($sType)-1)
											for ($k=$i; $k<count($tMember); $k++)
												$data .= $tMember[$k].(($k>=count($tMember)-1)?"":",");
										$params = array();
										$sValue = str_replace("?", " and ", $data);
										$sValue = str_replace(":", " or ", $data);
										$sValue = str_ireplace("Math", "math", $data);
										preg_match_all("/[a-zA-Z]+/i", strVal($data), $params);
										if (count($params[0]) > 0)
										{
											$params[0] = array_unique($params[0]);
											$params[0] = array_diff($params[0], $keywords);
											$sValue = "function(".join(",",$params[0]).") return ($sValue) end";
										}
										else
										{
											$sValue = "function() return ($sValue) end";	
										}
										$sRowScript .= "$sValue,";
										break;
									}
									default:
									{
										exit("ERROR: Row:$nRow Col:$nCol type '$sType[$i]' error!\n");
										break;
									}
								}
							}
							$sRowScript .= "},";
						}
						$sRowScript .= "},";
						break;
					}
					default:
					{
						exit("ERROR: Row:$nRow Col:$nCol type '$tType[$nCol]' not support!\n");
						break;
					}
				}
			}			
			$sScript .= "$sRowScript}\n";
		}
	}  
	fclose($hFile);  

	$sScript = iconv("gbk", "utf-8", $sScript);
	if (file_exists($sLuaFile))
	{
		$sOldScript = file_get_contents($sLuaFile);
		if ($sOldScript == $sScript)
		{
			return;
		}
	}
	file_put_contents($sLuaFile, $sScript);
}

$sMainFile = $sScriptDir.$DIRECTORY_SEPARATOR."Main.lua";
$hMainFile = fopen($sMainFile, "a");
if (!$hMainFile)
{
	exit("ERROR: Saving '$sMainFile' fail, break!\n");
}

foreach ($tLuaFileList as $k => $v)
{
	$sName = $v[0];
	$sFile = substr($v[1], 0, -4);
	$nPos = strlen($sScriptDir);
	$sFile = (substr($sFile, $nPos+1));
	fwrite($hMainFile, "require(\"Config/$sFile\")\n");
}
fclose($hMainFile);
?>
