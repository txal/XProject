<?php
//i 整形
//s 字符串
//t 表

error_reporting(E_ALL);

if (count($argv) < 3)
{
	exit("Please set the csv file dir and lua file dir");
}

$sXMLDir = $argv[1];
$sScriptDir = $argv[2];

if(!is_dir($sXMLDir))
{
	exit("Dir '$sXMLDir' is not found!");
}

if(!is_dir($sScriptDir))
{
	exit("Dir '$sScriptDir' is not found!");
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
			exit("Open dir '$sXMLDir' fail!");
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
		print("Dir '$sXMLDir' is not a dir or not found!\n");
	}
}

function XML2Lua($sXMLFile, $sScriptDir)
{
	global $tLuaFileList;
	global $DIRECTORY_SEPARATOR; 

	$nDs = strrpos($sXMLFile, $DIRECTORY_SEPARATOR);
	if (!$nDs) 
	{
		print("error: '$sXMLFile' extract name fail!");
		return;
	}
	$nDot = strrpos($sXMLFile, ".");
	$sFileName = substr($sXMLFile, $nDs + 1, $nDot - $nDs - 1);
	$sLuaIncFile = $sScriptDir.$DIRECTORY_SEPARATOR.$sFileName."Inc.lua";
	$sLuaFile = $sScriptDir.$DIRECTORY_SEPARATOR.$sFileName.".lua";

	print("Converting: $sFileName.xml => $sFileName.lua\n");

	$XML = new XMLReader();
	$XML->open($sXMLFile, "utf-8");

	$sRootTable = "";
	$sScript = "";
	array_push($tLuaFileList, array($sLuaIncFile, $sLuaFile));

	$tField = array(); 
	$tType = array();

	$nSheet = 0;
	$nRow = 0;
	$nCell = 0;
	$nData = 0;
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
			$nCell = 0;
			$nRow += 1;
		}
		if ($XML->name == "Cell" && $XML->nodeType == XMLReader::ELEMENT)
		{
			$nCell += 1;
		}
		if ($XML->name == "Data")
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
				$sValue = $XML->value;
				if ($nCell == 1)
				{
					$sSubTable = $sRootTable."[".intval($sValue)."]";
					$sScript .= "$sSubTable={}\n";
				}
				switch (substr($tType[$nCell],0,1))
				{
					case "i":
					{
						$sValue = intVal($sValue);
						$sScript .= "$sSubTable.$tField[$nCell]=$sValue\n";
						break;
					}
					case "s":
					{
						$sValue = "\"".strVal($sValue)."\"";
						$sScript .= "$sSubTable.$tField[$nCell]=$sValue\n";
						break;
					}
					case "t":
					{
						$sType = $tType[$nCell];
						$nTableLevel = substr_count($sType, "t");
						if ($nTableLevel == 0)
						{
							exit("'$sType' not support!\n");
						}
						if ($nTableLevel >= 2)
						{
							exit("'$sType' error, only support 1 levels table, break!\n");
						}
						$sType = substr($sType, 2, -1);
						$sSubTable1 = "$sSubTable.$tField[$nCell]";
						$sScript .= "$sSubTable1={}\n";
						$tSubTable = explode(";", $sValue);
						foreach ($tSubTable as $k => $v)
						{
							if ($v == "")
							{
								break;
							}
							$sSubTable2 = $sSubTable1."[".($k+1)."]";
							$sScript .= $sSubTable2."={}\n";
							$tMember = explode(",", $v);
							for ($i = 0; $i < strlen($sType); $i++)
							{
								if (!isset($tMember[$i]))
								{
									exit("Row:$nRow error, break!\n");
								}
								switch ($sType[$i])
								{
									case "i":
									{
										$nVal = intval($tMember[$i]);	
										$sScript .= $sSubTable2."[".($i+1)."]=".$nVal."\n";
										break;
									}
									case "s":
									{
										$sVal = "\"".strval($tMember[$i])."\"";
										$sScript .= $sSubTable2."[".($i+1)."]=$sVal\n";
										break;
									}
									default:
									{
										exit("Row:$nRow Col:$nCell type '$sType[$i]' error, break!\n");
										break;
									}
								}
							}
						}
						break;
					}
					default:
					{
						exit("Row:$nRow Col:$nCell type '$tType[$nCell]' not support, break!\n");
						break;
					}
				}
			}
		}
	}
	$XML->close();
	file_put_contents($sLuaIncFile, "$sRootTable = {}");
	file_put_contents($sLuaFile, $sScript);
}
$sMainFile = $sScriptDir.$DIRECTORY_SEPARATOR."Main.lua";
$hMainFile = fopen($sMainFile, "w");
if (!$hMainFile)
{
	exit("Open '$sMainFile' fail, break!\n");
}
foreach ($tLuaFileList as $k => $v)
{
	$sLuaIncFile = substr($v[0], 0, -4);
	$sIncFileName = substr($sLuaIncFile, strlen($sScriptDir)+1);
	fwrite($hMainFile, "require(\"Config/$sIncFileName\")\n");
	
	$sLuaFile = substr($v[1], 0, -4);
	$sFileName = substr($sLuaFile, strlen($sScriptDir)+1);
	fwrite($hMainFile, "require(\"Config/$sFileName\")\n");
}
fclose($hMainFile);
?>