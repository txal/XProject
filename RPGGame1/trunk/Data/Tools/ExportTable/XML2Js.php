<?php
//i 整形
//s 字符串
//t 表

error_reporting(E_ALL);
include_once("ClientFilterList.php");

if (count($argv) < 3)
{
	exit("ERROR: Please set the csv file dir and js file dir");
}

$sXMLDir = $argv[1];
$sScriptDir = $argv[2];

if(!is_dir($sXMLDir))
{
	exit("ERROR: Dir '$sXMLDir' is not found!");
}

if(!is_dir($sScriptDir))
{
	exit("ERROR: Dir '$sScriptDir' is not found!");
}

$DIRECTORY_SEPARATOR = '/';
$tJsFileList = array();


ProcDir($sXMLDir, $sScriptDir);
function ProcDir($sXMLDir, $sScriptDir)
{
	global $DIRECTORY_SEPARATOR;
	global $FILTER_LIST;

	if(is_dir($sXMLDir))
	{
		$Handle = opendir($sXMLDir);
		if (!$Handle)
		{
			exit("ERROR: Open dir '$sXMLDir' fail!");
		}

		while(($sFile = readdir($Handle)))
		{
			if($sFile == "." || $sFile == "..")
			{
				continue;
			}

			if(is_dir($sXMLDir.$DIRECTORY_SEPARATOR.$sFile))
			{
				$sSubXMLDir = $sXMLDir.$DIRECTORY_SEPARATOR.$sFile; 
				$sSubScriptDir = $sScriptDir.$DIRECTORY_SEPARATOR.$sFile;
				@mkdir($sSubScriptDir, 0777);
				ProcDir($sSubXMLDir, $sSubScriptDir);
			}
			elseif (isset($FILTER_LIST[substr($sFile, 0, strlen($sFile)-4)])) {
				print("##########################filter: $sFile\n");
			}
			else
			{
				$sXMLFile = $sXMLDir.$DIRECTORY_SEPARATOR.$sFile;
				$nDot = strrpos($sXMLFile, ".");
				if (!$nDot)
				{
					continue;
				}
				$sExt = substr($sXMLFile, $nDot + 1, strlen($sXMLFile) - $nDot);
				if (strtolower($sExt) == "xml")
				{
					XML2Js($sXMLFile, $sScriptDir);
				}
			}
		}
		closedir($Handle);
	}
	else
	{
		print("ERROR: Dir '$sXMLDir' is not a dir or not found!\n");
	}
}

//去掉多余的逗号
function RemoveComma($sScript)
{
	if ($sScript[strlen($sScript)-2] == ",")
	{
		$sScript = substr($sScript, 0, -2);
	}
	return $sScript;
}

function XML2Js($sXMLFile, $sScriptDir)
{
	global $tJsFileList;
	global $DIRECTORY_SEPARATOR; 

	$nDs = strrpos($sXMLFile, $DIRECTORY_SEPARATOR);
	if (!$nDs) 
	{
		print("ERROR: '$sXMLFile' extract name fail!");
		return;
	}
	$nDot = strrpos($sXMLFile, ".");
	$sFileName = substr($sXMLFile, $nDs + 1, $nDot - $nDs - 1);
	$sJsFile = $sScriptDir.$DIRECTORY_SEPARATOR.$sFileName.".js";
	$sJsIncFile = $sScriptDir.$DIRECTORY_SEPARATOR.$sFileName."Inc.js";

	print("Converting: $sFileName.xml => $sFileName.js\n");

	$XML = new XMLReader();
	if (!$XML->open($sXMLFile, "utf-8"))
	{
		exit("ERROR: Open '$sXMLFile' fail!\n");
	}

	$sScript = "";
	$sRootTable = "t";
	$sRawRootTable = "";
	$sRowScript = "";

	$tType = array();
	$tField = array(); 
	$tFieldSpec = array();
	$bNotHasFieldSpec = false;

	$nSheet = 0;
	$nRow = 0;
	$nData = 0;
	$nCell = 0;
	$nLastCell = 0;
	
	$keywords = array("math", "min", "max", "Math", "floor", "ceil", "pow", "random", "and", "or");
		
	while ($XML->read())
	{
		if ($XML->name == "Worksheet" && $XML->nodeType == XMLReader::ELEMENT)
		{
			$nRow = 0;
			$nSheet += 1;
			if ($nSheet == 1)
			{
				$XML->moveToNextAttribute();
				$sRootTable = "t";
				$sRawRootTable = $XML->value;
			}
			else
			{
				break;
			}
		}
		if ($XML->name == "Row" && $XML->nodeType == XMLReader::ELEMENT)
		{
			if ($nRow == 0)
			{
				$nTmpRow = $XML->getAttribute("ss:Index");
				if ($nTmpRow) 
					$nRow = $nTmpRow;
				else
					$nRow++;
			}
			else 
			{
				$nRow++;
			}
			if ($nRow >= 5 && $sRowScript)
			{
				$sRowScript = RemoveComma($sRowScript);
				$sScript .= "$sRowScript}\n";
			}
			$nCell = 0;
			$nLastCell = 0;
			$sRowScript = "";
		}
		if ($XML->name == "Cell" && $XML->nodeType == XMLReader::ELEMENT)
		{
			$nCell++;
		}
		if ($XML->name == "Data" || ($nRow >= 5 && $XML->name == "ss:Data"))
		{

			if ($XML->nodeType == XMLReader::ELEMENT)
			{
				$nData = 1;
			}
			else if ($XML->nodeType == XMLReader::END_ELEMENT)
			{
				$nData = 0;
			}
			
		}
		if ($nData > 0 && $XML->nodeType == XMLReader::TEXT)
		{
			if ($nRow == 2)
			{
				if (strlen($XML->value) == 1 && is_numeric($XML->value))
				{
					$bNotHasFieldSpec = false;
					$tFieldSpec[$nCell] = intval($XML->value);
				}
				else
				{
					$bNotHasFieldSpec = true;
					$tFieldSpec[$nCell]	= 0;
					$tField[$nCell] = $XML->value;
					for ($i=1; $i < $nCell-1; $i++)
					{
						if ($tField[$i] == $XML->value)
							exit("ERROR: Duplication columns '$XML->value'!\n");
					}
				}
	
			}
			else if ($nRow == 3)
			{
				if ($bNotHasFieldSpec)
				{
					$tType[$nCell] = $XML->value;
				}
				else
				{
					$tField[$nCell] = $XML->value;
					for ($i=1; $i < $nCell-1; $i++)
					{
						if ($tField[$i] == $XML->value)
							exit("ERROR: Duplication columns '$XML->value'!\n");
					}
				}
			}
			else if ($nRow == 4)
			{
				if ($bNotHasFieldSpec)
				{//注释行

				}
				else
				{
					$tType[$nCell] = $XML->value;
				}
			}
			else if (!$bNotHasFieldSpec && $nRow == 5)
			{//注释行
			}
			else if ($nRow >= 5)
			{
				// if ($sFileName == "AppellationConf")
				// {
				// 	print_r($tType);
				// 	print("\n");
				// }
				if ($tFieldSpec[$nCell] == 1) 
				{
					$nLastCell = $nCell;
					continue;	
				}
				if ($nLastCell + 1 != $nCell)
				{
					$nErrCell = $nLastCell + 1;
					exit("ERROR: [$sXMLFile] Row:$nRow Col:$nErrCell->$nCell ColName:$tField[$nErrCell] can not read data!!!\n");
				}
				$nLastCell = $nCell;
				$sValue = $XML->value;
				if ($nCell == 1)
				{
					$key = $sValue;
					if (is_numeric($sValue))
						$key = floatval($sValue);
					else
						$key = "\"$key\"";
					$sSubTable = $sRootTable."[$key]";
					$sRowScript .= "$sSubTable={";
				}
				$sField = trim($tField[$nCell]);
				switch (substr($tType[$nCell],0,1))
				{
					case "i":
					{
						if (!is_numeric($sValue))
						{
							exit("ERROR: Row:$nRow Col:$tField[$nCell] value error!\n");
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
							$sValue = "function(".join(",",$params[0])."){ return ($sValue) }";
							$sValue = preg_replace("/math/","Math",$sValue);
							$sValue = preg_replace("/and/","&&",$sValue);
						}
						else
						{
							$sValue = "function(){return ($sValue)}";
						}
						$sRowScript .= "$tField[$nCell]:$sValue,";
						break;
					}
					case "c":
					{
						break;
					}
					case "t":
					{
						$sType = $tType[$nCell];
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
						$sField = trim($tField[$nCell]);
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
									exit("ERROR: Row:$nRow Col:$tField[$nCell] is empty!\n");
								}
								switch ($sType[$i])
								{
									case "i":
									{
										$nVal = $tMember[$i];
										if (!is_numeric($nVal))
										{
											exit("ERROR: Row:$nRow Col:$tField[$nCell] value error!\n");
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
										exit("ERROR: Row:$nRow Col:$nCell type '$sType[$i]' error!\n");
										break;
									}
								}
							}
							$sRowScript = RemoveComma($sRowScript);
							$sRowScript .= "],";
						}
						$sRowScript = RemoveComma($sRowScript);
						$sRowScript .= "],";
						break;
					}
					default:
					{
						exit("ERROR: Row:$nRow Col:$nCell type '$tType[$nCell]' not support!\n");
						break;
					}
				}
			}
		}
	}
	$XML->close();
	if ($sRowScript)
	{
		$sRowScript = RemoveComma($sRowScript);
		$sScript .= "$sRowScript}\n";
	}
	$sScript = "var $sRawRootTable={}\nvar t=$sRawRootTable\n$sScript\nmodule.exports=$sRootTable";
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
	    ."if (!(id in $sRootTable)) { console.error(\"$sRootTable: 配置编号:\"+id+\" 不存在\"); return null }\n\t"
		."if (key === null) {\n\t\t"
		."return $sRootTable"."[id]\n\t"
		."} else {\n\t\t"
        ."var conf = $sRootTable"."[id]\n\t\t"
        ."if (!(key in conf)) { console.error(\"$sRootTable: 配置编号:\"+id+\" 键:\"+key+\" 不存在\"); return null }\n\t\t"
		."return $sRootTable"."[id][key]\n\t"
		."}\n}\n\n"
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