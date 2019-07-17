<?php
//i 整形
//s 字符串
//t 表

error_reporting(E_ALL);

if (count($argv) < 3)
{
	exit("ERROR: Please set the csv file dir and js file dir");
}

//要过滤的文件
$FILTER_LIST = array(
	"KeywordConf.xml"=>true,
);

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

	if(is_dir($sXMLDir)) {
		$Handle = opendir($sXMLDir);
		if (!$Handle)
			exit("ERROR: Open dir '$sXMLDir' fail!");

		while(($sFile = readdir($Handle))) {
			if($sFile == "." || $sFile == "..")
				continue;

			if(is_dir($sXMLDir.$DIRECTORY_SEPARATOR.$sFile)) {
				$sSubXMLDir = $sXMLDir.$DIRECTORY_SEPARATOR.$sFile; 
				$sSubScriptDir = $sScriptDir.$DIRECTORY_SEPARATOR.$sFile;
				@mkdir($sSubScriptDir, 0777);
				ProcDir($sSubXMLDir, $sSubScriptDir);

			} elseif (isset($FILTER_LIST[$sFile])) {
				print("------filter: ".$sFile."------\n");

			} else {
				$sXMLFile = $sXMLDir.$DIRECTORY_SEPARATOR.$sFile;
				$nDot = strrpos($sXMLFile, ".");
				if (!$nDot) continue;

				$sExt = substr($sXMLFile, $nDot + 1, strlen($sXMLFile) - $nDot);
				if (strtolower($sExt) == "xml")
					XML2Js($sXMLFile, $sScriptDir);
			}
		}
		closedir($Handle);
	}
	else
		print("ERROR: Dir '$sXMLDir' is not a dir or not found!\n");
}

//去掉多余的逗号
function RemoveComma($sScript)
{
	if ($sScript[strlen($sScript)-2] == ",")
		$sScript = substr($sScript, 0, -2);
	return $sScript;
}

function XML2Js($sXMLFile, $sScriptDir)
{
	global $tJsFileList;
	global $DIRECTORY_SEPARATOR; 

	$nDs = strrpos($sXMLFile, $DIRECTORY_SEPARATOR);
	if (!$nDs) {
		print("ERROR: '$sXMLFile' extract name fail!");
		return;
	}

	$nDot = strrpos($sXMLFile, ".");
	$sFileName = substr($sXMLFile, $nDs + 1, $nDot - $nDs - 1);
	$sJsFile = $sScriptDir.$DIRECTORY_SEPARATOR.$sFileName.".json";

	print("Converting: $sFileName.xml => $sFileName.js\n");

	$XML = new XMLReader();
	if (!$XML->open($sXMLFile, "utf-8"))
		exit("ERROR: Open '$sXMLFile' fail!\n");

	$sScript = "";
	$sRootTable = "";

	$tField = array(); 
	$tType = array();

	$nSheet = 0;
	$nRow = 0;
	$nData = 0;
	$nCell = 0;
	$nLastCell = 0;
	
	$keywords = array("math", "min", "max", "Math", "floor", "ceil", "pow", "random");
		
	while ($XML->read())
	{
		if ($XML->name == "Worksheet" && $XML->nodeType == XMLReader::ELEMENT) {
			$nRow = 0;
			$nSheet += 1;
			if ($nSheet == 1) {
				$XML->moveToNextAttribute();
				$sRootTable = $XML->value;
				$tRootTable = array();
			}
			else
				break;
		}
		if ($XML->name == "Row" && $XML->nodeType == XMLReader::ELEMENT) {
			if ($nRow == 0) {
				$nTmpRow = $XML->getAttribute("ss:Index");
				if ($nTmpRow) 
					$nRow = $nTmpRow;
				else
					$nRow++;
			}
			else 
				$nRow++;

			$nCell = 0;
			$nLastCell = 0;
		}

		if ($XML->name == "Cell" && $XML->nodeType == XMLReader::ELEMENT)
			$nCell++;

		if ($XML->name == "Data" || ($nRow >= 5 && $XML->name == "ss:Data")) {

			if ($XML->nodeType == XMLReader::ELEMENT)
				$nData = 1;
			else if ($XML->nodeType == XMLReader::END_ELEMENT)
				$nData = 0;
		}

		if ($nData > 0 && $XML->nodeType == XMLReader::TEXT)
		{
			if ($nRow == 2)
				$tField[$nCell] = $XML->value;
			if ($nRow == 3)
				$tType[$nCell] = $XML->value;

			if ($nRow == 4) /* 注释行 */ {
			}

			if ($nRow >= 5) {
				if ($nLastCell + 1 != $nCell) {
					$nErrCell = $nLastCell + 1;
					exit("ERROR: [$sXMLFile] Row:$nRow Col:$nLastCell->$nCell ColName:$tField[$nErrCell] can not read data!!!\n");
				}
				$nLastCell = $nCell;
				$sValue = $XML->value;
				if ($nCell == 1) {
					$key = $sValue;
					if (is_numeric($sValue))
						$key = floatval($sValue);
					$tRootTable[$key] = array();
					$tSubTable = &$tRootTable[$key];
				}
				$sField = trim($tField[$nCell]);
				switch (substr($tType[$nCell],0,1)) {
					case "i": {
						if (!is_numeric($sValue))
							exit("ERROR: Row:$nRow Col:$tField[$nCell] value error!\n");

						$tSubTable[$sField] = floatval($sValue);
						break;
					}
					case "b": {
						$iValue = intVal($sValue);
						$sValue = $iValue != 0 ? "true" : "false";
						$tSubTable[$sField] = $sValue;
						break;
					}
					case "s": {
						$sValue = "\"".strVal($sValue)."\"";
						$tSubTable[$sField] = $sValue;
						break;
					}
					case "e": {
						$params = array();
						preg_match_all("/[a-zA-Z]+/i", strVal($sValue), $params);
						if (count($params[0]) > 0)
						{
							$params[0] = array_unique($params[0]);
							$params[0] = array_diff($params[0], $keywords);
							$sValue = "function(".join(",",$params[0])."){ return ($sValue); }";
							$sValue = preg_replace("/math/","Math",$sValue);
						}
						else
						{
							$sValue = "function(){ return ($sValue); }";
						}
						$tSubTable[$sField] = $sValue;
						break;
					}
					case "t": {
						$sType = $tType[$nCell];
						$nTableLevel = substr_count($sType, "t");
						if ($nTableLevel == 0)
							exit("ERROR: '$sType' not support!\n");
						if ($nTableLevel >= 2)
							exit("ERROR: '$sType' error, only support 1 levels table, break!\n");

						$sType = substr($sType, 2, -1);
						$sField = trim($tField[$nCell]);

						$tSubTable[$sField] = array();
						$tSubTable1 = &$tSubTable[$sField]; 

						$tSubType = explode(";", $sValue);
						foreach ($tSubType as $k => $v) {
							if ($v == "") break;

							$tSubTable2 = array();	
							$tMember = explode(",", $v);
							for ($i = 0; $i < strlen($sType); $i++) {
								if (!isset($tMember[$i]))
									exit("ERROR: Row:$nRow Col:$tField[$nCell] is empty!\n");

								switch ($sType[$i]) {
									case "i": {
										$nVal = $tMember[$i];
										if (!is_numeric($nVal))
											exit("ERROR: Row:$nRow Col:$tField[$nCell] value error!\n");
										array_push($tSubTable2, floatval($nVal));
										break;
									}
									case "b": {
										$iValue = intVal($tMember[$i]);
										$sValue = $iValue != 0 ? "true" : "false";	
										array_push($tSubTable2, $sValue);
										break;
									}
									case "s": {
										$sVal = "\"".strval($tMember[$i])."\"";
										array_push($tSubTable2, $sVal);
										break;
									}
									case "e": {
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
											$sValue = "function(".join(",",$params[0])."){ return ($data); }";
											$sValue = preg_replace("/math/","Math",$sValue);
										}
										else
										{
											$sValue = "function(){ return ($tMember[$i]); }";
										}											
										array_push($tSubTable2, $sValue);
										break;
									}
									default: {
										exit("ERROR: Row:$nRow Col:$nCell type '$sType[$i]' error!\n");
										break;
									}
								}
							}
							array_push($tSubTable1, $tSubTable2);
						}
						break;
					}
					default: {
						exit("ERROR: Row:$nRow Col:$nCell type '$tType[$nCell]' not support!\n");
						break;
					}
				}
			}
		}
	}
	$XML->close();
	$tPHPData = array();
	$tPHPData[$sRootTable] = $tRootTable;
	file_put_contents($sJsFile, json_encode($tPHPData));
	// $sScript = "var $sRootTable = {};\n$sScript\nmodule.exports = $sRootTable;";
	// if (file_exists($sJsFile))
	// {
	// 	$sOldScript = file_get_contents($sJsFile);
	// 	if ($sOldScript != $sScript) 
	// 	{
	// 		file_put_contents($sJsFile, $sScript);
	// 		array_push($tJsFileList, array($sJsFile, $sRootTable));
	// 	}
	// }
	// else
	// {
	// 	file_put_contents($sJsFile, $sScript);
	// 	array_push($tJsFileList, array($sJsFile, $sRootTable));
	// }
}

// foreach ($tJsFileList as $k => $v)
// {
// 	if (file_exists($v[0]))
// 	{
// 		continue;
// 	}
// 	$sIncFileName = strrchr($v[0], $DIRECTORY_SEPARATOR);
// 	$sIncFileName = substr($sIncFileName, 1, -3);

// 	$sFileName = strrchr($v[1], $DIRECTORY_SEPARATOR);
// 	$sFileName = substr($sFileName, 1, -3);

// 	$sRootTable = $v[2];
// 	$sHeader = 
// 	"var $sRootTable = require(\"$sFileName\");\n"
// 		."var fnExport = {};\n\n"
// 		."fnExport.getConf = function (id, key = null) {\n\t"
// 	    ."if (!(id in $sRootTable)) {\n\t\t"
//         ."throw new Error(\"$sRootTable: 配置编号:\"+id+\" 不存在\");\n\t}\n\t"
// 		."if (key === null) {\n\t\t"
// 		."return $sRootTable"."[id];\n\t"
// 		."} else {\n\t\t"
//         ."var conf = $sRootTable"."[id];\n\t\t"
//         ."if (!(key in conf)) {\n\t\t\t"
//         ."throw new Error(\"$sRootTable: 配置编号:\"+id+\" 键:\"+key+\" 不存在\");\n\t\t}\n\t\t"
// 		."return $sRootTable"."[id][key];\n\t"
// 		."}\n};\n\n"
// 		."fnExport.checkConf = function () {\n};\n\n"
// 		."fnExport.getAllConf = function () {\n\treturn $sRootTable;\n};\n\n"
// 		."fnExport.getMaxConf = function () {\n\t"
// 		."var tConf = Object.keys($sRootTable);\n\t"
// 		."tConf.sort(sortNumber);\n\t"
// 		."function sortNumber(a,b){ return b - a}\n\t"
// 		."var id = tConf[0];\n\t"
// 		."return $sRootTable"."[id];\n};\n\n"
// 		."module.exports = fnExport;";
// 	file_put_contents($v[0], $sHeader);
// }
?>