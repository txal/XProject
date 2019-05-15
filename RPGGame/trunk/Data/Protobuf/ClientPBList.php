<?php
    $Handle = opendir("./");
    if (!$Handle)
    {
        exit("ERROR: Open dir fail!");
    }

    $tFileArray = array();
    while(($sFile = readdir($Handle)))
    {
        if($sFile == "." || $sFile == "..")
        {
            continue;
        }

        $nDot = strrpos($sFile, ".");
        if (!$nDot)
        {
            continue;
        }
        $sExtend = substr($sFile, $nDot + 1, strlen($sFile) - $nDot);
        if (strtolower($sExtend) == "proto")
        {
            $sFileName = substr($sFile, 0, -6);
			$cont = file_get_contents($sFile);
			$cont = preg_replace("/(\r\n)|(\n)/", "\\n", $cont);
			$cont = preg_replace("/\"/", '\\"', $cont);
			file_put_contents("proto_".$sFileName.".js", "var $sFileName = \"$cont\";\nmodule.exports = $sFileName;\n");
            array_push($tFileArray, "$sFileName");
            echo "$sFile\n";
        }
    }
    closedir($Handle);
    $sScript = "var protoFiles = \n{\n";
    for ($i = 0; $i < count($tFileArray); $i++)
    {
        if ($i != count($tFileArray) - 1)
        {
			$sScript .= "$tFileArray[$i]: require(\"proto_$tFileArray[$i]\"),\n";
        }
        else
        {
			$sScript .= "$tFileArray[$i]: require(\"proto_$tFileArray[$i]\")";
        }
    }
    $sScript .= "\n};\n\nmodule.exports = protoFiles;";
    file_put_contents("protoFiles.js", $sScript);
    echo "make sucess\n";
?>