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
            $sFileName = $sFile;
            $sSubStr = strchr($sFileName, "/");
            if ($sSubStr)
            {
               $sFileName = $sSubStr;
            }
            array_push($tFileArray, "$sFileName");
            echo "$sFile\n";
        }
    }
    closedir($Handle);
    $sScript = "local tProtoList =\n{\n";
    for ($i = 0; $i < count($tFileArray); $i++)
    {
        if ($i != count($tFileArray) - 1)
        {
            $sScript .= "\"$tFileArray[$i]\",\n" ;
        }
        else
        {
            $sScript .= "\"$tFileArray[$i]\"";
        }
    }
    $sScript .= "\n};\n\nfunction LoadProto(sPath)\n\tassert(parser.register(tProtoList, sPath), \"load proto faild!\")\nend\n\n"
        ."function pbc_encode(proto, value)\n\treturn protobuf.encode(proto, value)\nend\n\n"
        ."function pbc_decode(proto, value, length)\n\tif not proto or not value then\n\t\treturn\n\tend\n\treturn protobuf.decode(proto, value, length)\nend\n\n";
    file_put_contents("LoadPBCProto.lua", $sScript);
    echo "make sucess\n";
?>