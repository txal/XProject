<?php
//i 整形
//s 字符串
//t 表

error_reporting(E_ALL);

if (count($argv) < 3)
{
	exit("ERROR: Please set the csv file dir and lua file dir");
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
$tLuaFileList = array();

ProcDir($sXMLDir, $sScriptDir);

function ProcDir($sXMLDir, $sScriptDir)
{
	global $DIRECTORY_SEPARATOR; 

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
					XML2Lua($sXMLFile, $sScriptDir);
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

function XML2Lua($sXMLFile, $sScriptDir)
{
	global $tLuaFileList;
	global $DIRECTORY_SEPARATOR; 

	$nDs = strrpos($sXMLFile, $DIRECTORY_SEPARATOR);
	if (!$nDs) 
	{
		print("ERROR: '$sXMLFile' extract name fail!");
		return;
	}
	$nDot = strrpos($sXMLFile, ".");
	$sFileName = substr($sXMLFile, $nDs + 1, $nDot - $nDs - 1);
	$sLuaFile = $sScriptDir.$DIRECTORY_SEPARATOR.$sFileName.".lua";

	print("Converting: $sFileName.xml => $sFileName.lua\n");

	$XML = new XMLReader();
	if (!$XML->open($sXMLFile, "utf-8"))
	{
		exit("ERROR: Open '$sXMLFile' fail!\n");
	}

	$sScript = "";
	$sRootTable = "";
	$sRowScript = "";
	array_push($tLuaFileList, $sLuaFile);

	$tField = array(); 
	$tType = array();

	$nSheet = 0;
	$nRow = 0;
	$nData = 0;
	$nCell = 0;
	$nLastCell = 0;
	while ($XML->read())
	{
		if ($XML->name == "Worksheet" && $XML->nodeType == XMLReader::ELEMENT)
		{
			$nRow = 0;
			$nSheet += 1;
			if ($nSheet == 1)
			{
				$XML->moveToNextAttribute();
				$sRootTable = $XML->value;
			}
			else
			{
				break;
			}
		}
		if ($XML->name == "Row" && $XML->nodeType == XMLReader::ELEMENT)
		{
			if ($nRow >= 4 && $sRowScript)
			{
				$sScript .= "$sRowScript}\n";
			}
			$nRow++;
			$nCell = 0;
			$nLastCell = 0;
			$sRowScript = "";
		}
		if ($XML->name == "Cell" && $XML->nodeType == XMLReader::ELEMENT)
		{
			$nCell++;
		}
		if ($XML->name == "Data" || ($nRow >= 4 && $XML->name == "ss:Data"))
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
			if ($nRow == 1)
			{
				$tField[$nCell] = $XML->value;
			}
			if ($nRow == 2)
			{
				$tType[$nCell] = $XML->value;
			}
			if ($nRow == 3)
			{/* 注释行 */}
			if ($nRow >= 4)
			{
				if ($nLastCell + 1 != $nCell)
				{
					$nErrCell = $nLastCell + 1;
					exit("ERROR: [$sXMLFile] Row:$nRow Col:$nLastCell->$nCell ColName:$tField[$nErrCell] can not read data!!!\n");
				}
				$nLastCell = $nCell;
				$sValue = $XML->value;
				if ($nCell == 1)
				{
					$sSubTable = $sRootTable."[".intval($sValue)."]";
					$sRowScript .= "$sSubTable={";
				}
				switch (substr($tType[$nCell],0,1))
				{
					case "i":
					{
						if (!is_numeric($sValue))
						{
							exit("ERROR: Row:$nRow Col:$tField[$nCell] value error!\n");
						}
						$sValue = $sValue;
						$sRowScript .= "$tField[$nCell]=$sValue,";
						break;
					}
					case "b":
					{
						$iValue = intVal($sValue);
						$sValue = $iValue != 0 ? "true" : "false";
						$sRowScript .= "$tField[$nCell]=$sValue,";
						break;
					}
					case "s":
					{
						$sValue = "\"".strVal($sValue)."\"";
						$sRowScript .= "$tField[$nCell]=$sValue,";
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
						$sRowScript .= "$tField[$nCell]={";
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
									default:
									{
										exit("ERROR: Row:$nRow Col:$nCell type '$sType[$i]' error!\n");
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
		$sScript .= "$sRowScript}\n";
	}
	$sScript = "$sRootTable={}\n$sScript";
	file_put_contents($sLuaFile, $sScript);
}
$sMainFile = $sScriptDir.$DIRECTORY_SEPARATOR."Main.lua";
$hMainFile = fopen($sMainFile, "w");
if (!$hMainFile)
{
	exit("ERROR: Open '$sMainFile' fail, break!\n");
}
foreach ($tLuaFileList as $k => $v)
{
	$sLuaFile = substr($v, 0, -4);
	$sFileName = substr($sLuaFile, strlen($sScriptDir)+1);
	fwrite($hMainFile, "require(\"Config/$sFileName\")\n");
}
fclose($hMainFile);
?>