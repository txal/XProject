<?php
//i 整形
//s 字符串
//t 表

error_reporting(E_ALL);
include_once("ClientFilterList.php");

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
$tJsFileList = array();

ProcDir($sCSVDir, $sScriptDir);

function ProcDir($sCSVDir, $sScriptDir)
{
	global $DIRECTORY_SEPARATOR, $FILTER_LIST;

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
			else if (isset($FILTER_LIST[substr($sFile, 0, strlen($sFile)-4)]))
			{
				print("#####################filter: $sFile\n");
			}
			else
			{
				$sCSVFile = $sCSVDir.$DIRECTORY_SEPARATOR.$sFile;
				$nDot = strrpos($sCSVFile, ".");
				if (!$nDot) continue;
				$sExt = substr($sCSVFile, $nDot + 1, strlen($sCSVFile) - $nDot);
				if (strtolower($sExt) == "csv")
				{
					CSV2Js($sCSVFile, $sScriptDir);
				}
			}
		}
		closedir($Handle);
	}
	else
	{
		print("ERROR: Dir '$sDir' is not a dir or not found!\n");
	}
}

function CSV2Js($sCSVFile, $sScriptDir)
{
	global $tJsFileList;
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
	$sJsFile = $sScriptDir.$DIRECTORY_SEPARATOR.$sFileName.".js";
	$sJsIncFile = $sScriptDir.$DIRECTORY_SEPARATOR.$sFileName."Inc.js";

	print("Converting: ${sFileName}.csv => ${sFileName}.js\n");

	$sScript = "";
	$sRawRootTable = $sPrefix.$sFileName;
	$sRootTable = "t";

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
			if ($tFieldSpec[0] == "1") 
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
				if ($tFieldSpec[$k] == "1")
				{
					continue;
				}
				$nValidColumn++;
				$nCol = $k;
				$sValue = $v;
				$sField = trim($tField[$k]);
				switch(substr($tType[$nCol],0,1))
				{
					case "i":
					{
						if (!is_numeric($sValue))
						{
							exit("ERROR: Row:$nRow Col:$tField[$nCol] value error!\n");
						}
						$sValue = $sValue;
						$sRowScript .= "$sField:$sValue,";
						break;
					}
					case "b":
					{
						$iValue = intVal($sValue);
						$sValue = $iValue != 0 ? "true" : "false";
						$sRowScript .= "$sField:$sValue,";
						break;
					}
					case "s":
					{
						$sValue = "\"".strVal($sValue)."\"";
						$sRowScript .= "$sField:$sValue,";
						break;
					}
					case "e":
					{
						$params = array();
						preg_match_all("/[a-zA-Z]+/i", strVal($sValue), $params);
						if (count($params[0]) > 0)
						{
							$params[0] = array_unique($params[0]);
							$params[0] = array_diff($params[0], $keywords);
							$sValue = "function(".join(",",$params[0])."){return ($sValue)}";
							$sValue = preg_replace("/math/","Math",$sValue);
							$sValue = preg_replace("/and/","&&",$sValue);
						}
						else
						{
							$sValue = "function(){return ($sValue)}";
						}
						$sRowScript .= "$tField[$nCol]:$sValue,";
						break;
					}
					case "c":
					{
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
						$sField = trim($tField[$nCol]);
						$sRowScript .= "$sField:[";
						$tSubTable = explode(";", $sValue);
						foreach ($tSubTable as $k => $v)
						{
							if ($v == "")
							{
								break;
							}
							$sRowScript .= "[";
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
										preg_match_all("/[a-zA-Z]+/i", strVal($data), $params);
										if (count($params[0]) > 0)
										{
											$params[0] = array_unique($params[0]);
											$params[0] = array_diff($params[0], $keywords);
											$sValue = "function(".join(",",$params[0])."){return ($data)}";
											$sValue = preg_replace("/math/","Math",$sValue);
											$sValue = preg_replace("/and/","&&",$sValue);
										}
										else
										{
											$sValue = "function(){return ($tMember[$i])}";
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
							$sRowScript = removeComma($sRowScript);
							$sRowScript .= "],";
						}
						$sRowScript = removeComma($sRowScript);
						$sRowScript .= "],";
						break;
					}
					default:
					{
						exit("ERROR: Row:$nRow Col:$nCol type '$tType[$nCol]' not support!\n");
						break;
					}
				}	
			}			
			if ($nValidColumn > 0)
			{
				$sRowScript = removeComma($sRowScript);
				$sScript .= "$sRowScript}\n";
			}
		}
	}  
	fclose($hFile);  

	$sScript = "var $sRawRootTable={}\nvar $sRootTable=$sRawRootTable\n$sScript\nmodule.exports=$sRootTable";
	$sScript = iconv("gbk", "utf-8", $sScript);
	if (file_exists($sJsFile))
	{
		$sOldScript = file_get_contents($sJsFile);
		if ($sOldScript == $sScript) 
		{
			return;
		}
	}
	file_put_contents($sJsFile, $sScript);
	array_push($tJsFileList, array($sJsIncFile, $sJsFile, $sRawRootTable));
}

//去掉多余的逗号
function removeComma($sScript)
{
	if ($sScript[strlen($sScript)-2] == ",")
	{
		$sScript = substr($sScript, 0, -2);
	}
	return $sScript;
}

foreach ($tJsFileList as $k => $v)
{
	if (file_exists($v[0]))
	{
		continue;
	}
	$sIncFileName = strrchr($v[0], $DIRECTORY_SEPARATOR);
	$sIncFileName = substr($sIncFileName, 1, -3);

	$sFileName = strrchr($v[1], $DIRECTORY_SEPARATOR);
	$sFileName = substr($sFileName, 1, -3);

	$sRootTable = $v[2];
	$sHeader = 
	"var $sRootTable = require(\"$sFileName\")\n"
		."var fnExport = {}\n\n"
		."fnExport.getConf = function (id, key = null) {\n\t"
	    ."if (!(id in $sRootTable)) { console.error(\"$sRootTable: 配置编号:\"+id+\" 不存在\"); return null}\n\t"
		."if (key === null) {\n\t\t"
		."return $sRootTable"."[id]\n\t"
		."} else {\n\t\t"
        ."var conf = $sRootTable"."[id]\n\t\t"
        ."if (!(key in conf)) { console.error(\"$sRootTable: 配置编号:\"+id+\" 键:\"+key+\" 不存在\"); return null}\n\t\t"
		."return $sRootTable"."[id][key]\n\t"
		."}\n}\n\n"
		."fnExport.checkConf = function () {\n}\n\n"
		."fnExport.getAllConf = function () {\n\treturn $sRootTable\n}\n\n"
		."fnExport.getMaxConf = function () {\n\t"
		."var tConf = Object.keys($sRootTable)\n\t"
		."tConf.sort(sortNumber)\n\t"
		."function sortNumber(a,b){ return b - a}\n\t"
		."var id = tConf[0]\n\t"
		."return $sRootTable"."[id]\n}\n\n"
		."module.exports = fnExport";
	file_put_contents($v[0], $sHeader);
}

?>
