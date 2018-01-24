<?php
//i 整形
//s 字符串
//t 表

error_reporting(E_ALL);

if (count($argv) < 3)
	exit("Please set the csv file dir and lua file dir");

$sCSVDir = $argv[1];
$sScriptDir = $argv[2];

if(!is_dir($sCSVDir))
	exit("Dir '$sCSVDir' is not found!");

if(!is_dir($sScriptDir))
	exit("Dir '$sScriptDir' is not found!");

$DIRECTORY_SEPARATOR = '/';
$tLuaFileList = array();

ProcDir($sCSVDir, $sScriptDir);

function ProcDir($sCSVDir, $sScriptDir)
{
	global $DIRECTORY_SEPARATOR;

	if(is_dir($sCSVDir))
	{
		$Handle = opendir($sCSVDir);
		if (!$Handle) exit();

		while(($sFile = readdir($Handle)))
		{
			if($sFile == "." || $sFile == "..")
				continue;

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
		print("Dir '$sDir' is not a dir or not found!\n");
}

function CSV2Lua($sCSVFile, $sScriptDir)
{
	global $tLuaFileList;
	global $DIRECTORY_SEPARATOR; 

	$sPrefix = "cf";

	$hFile = fopen($sCSVFile, "r");  
	if (!$hFile) exit();

	$nDs = strrpos($sCSVFile, $DIRECTORY_SEPARATOR);
	if (!$nDs) 
	{
		print("error: '$sCSVFile' extract name fail!");
		return;
	}
	$nDot = strrpos($sCSVFile, ".");
	$sFileName = substr($sCSVFile, $nDs + 1, $nDot - $nDs - 1);
	$sLuaFile = $sScriptDir.$DIRECTORY_SEPARATOR.$sFileName.".lua";

	print("Converting: $sFileName.csv => $sFileName.lua\n");

	$sRootTable = $sPrefix.$sFileName;
	$sScript = "local $sRootTable={}\n";
	array_push($tLuaFileList, array($sRootTable, $sLuaFile));

	$nRow = 0;
	$tType = array();
	$tField = array();
	while ($sRow = fgets($hFile))
	{
		//在 $LANG=zh_CN.UTF-8 的时候用 fgetcsv 读取会乱码
		$sRow = iconv("gbk", "utf-8", $sRow);
		$tRow = str_getcsv($sRow);

		$nRow++;
		if ($nRow == 1)
			$tField = $tRow;
		else if ($nRow == 2)
			$tType = $tRow;
		else if ($nRow == 3)
		{/*注释行*/}
		else if ($nRow >= 4)
		{
			$sSubTable = $sRootTable."[".intval($tRow[0])."]";
			$sScript .= $sSubTable."={}\n";
			foreach ($tRow as $k => $v)
			{
				$nCol = $k;
				$sData = $v;
				switch($tType[$nCol])
				{
					case "i":
					{
						if ($sData == "")
							exit("Row:$nRow Col:".($nCol+1)." error, break!\n");
						$nVal = intval($sData);
						$sScript .= "$sSubTable.$tField[$nCol]=$nVal\n";
						break;
					}
					case "s":
					{
						$sVal = "\"".strval($sData)."\"";
						$sScript .= "$sSubTable.$tField[$nCol]=$sVal\n";
						break;
					}
					default:
					{
						$sType = $tType[$nCol];
						$nTableNum = substr_count($sType, "t");
						if ($nTableNum == 0)
							exit("'$sType' not support!\n");
						if ($nTableNum >= 2)
							exit("'$sType' error, only support 1 levels table, break!\n");
						$sType = substr($sType, 2, -1);

						$sSubTable1 = "$sSubTable.$tField[$nCol]";
						$sScript .= "$sSubTable1={}\n";
						$tSubTable = explode(";", $sData);
						foreach ($tSubTable as $k => $v)
						{
							if ($v == "") break;
							$sSubTable2 = $sSubTable1."[".($k+1)."]";
							$sScript .= "$sSubTable2={}\n";
							$tMember = explode(",", $v);
							for ($i = 0; $i < strlen($sType); $i++)
							{
								if (!isset($tMember[$i]))
									exit("Row:$nRow Col:".($nCol+1)." error, break!\n");
								switch ($sType[$i])
								{
									case "i":
									{
										$nVal = intval($tMember[$i]);	
										$sScript .= $sSubTable2."[".($i+1)."]=$nVal\n";
										break;
									}
									case "s":
									{
										$sVal = "\"".strval($tMember[$i])."\"";
										$sScript .= $sSubTable2."[".($i+1)."]=$sVal\n";
										break;
									}
									default:
									exit("Row:$nRow Col:".($nCol+1)." error, break!\n");
								}
							}
						}
					}
				}
			}			
		}
	}  
	fclose($hFile);  
	$sScript .= "\n return $sRootTable\n";
	$hLuaFile = fopen($sLuaFile, "w");
	if (!$hLuaFile) exit("Saving '$sLuaFile' fail, break!\n");
	fwrite($hLuaFile, $sScript, strlen($sScript));
	fclose($hLuaFile);
}
$sMainFile = $sScriptDir.$DIRECTORY_SEPARATOR."Main.lua";
$hMainFile = fopen($sMainFile, "w");
if (!$hMainFile) exit("Saving '$sMainFile' fail, break!\n");
foreach ($tLuaFileList as $k => $v)
{
	$sName = $v[0];
	$sFile = substr($v[1], 0, -4);
	$nPos = strlen($sScriptDir);
	$sFile = (substr($sFile, $nPos+1));
	fwrite($hMainFile, "$sName=require(\"$sFile\")\n");
}
fclose($hMainFile);
?>
