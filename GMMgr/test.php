<?php

//       $data = array("name" => "momo","age" => 15,"sex" => '');
//
//       ksort($data);
//
//       $str = '';
//       foreach ($data as $key=>$val) {
//           $str .= $key."=".$val;
//       }
//       echo $str;

        $a = md5('');
        $b = md5("");

        if ($a === $b) {
            echo 1;
        } else {
            echo 0;
        }
