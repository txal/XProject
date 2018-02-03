<?php


        require_once("../../common.php");

//        //获取用户信息
//        $app_key = "abcdef";
//        $authorize_code = "1234560";
//        $time = 1500034256;
//
//        $url = "http://127.0.0.1:90/pay/bingniao/token.php";
//        $data = array("app_key"=>$app_key, "authorize_code"=>$authorize_code, "time"=>$time);
//
//        ksort($data);
//        $strSign = "";
//        foreach ($data as $key => $val){
//            $strSign .= $key."=".$val."&";
//        }
//        $strSign[strlen($strSign) -1] = "";
//        $data['sign'] = md5($strSign);
//
//        $jdata = json_encode($data);
//        $tRes = sendPost($url, $jdata);
//
//        print_r($tRes['ret']);



        //支付结果通知
//        $url = "http://127.0.0.1:90/pay/bingniao/payReturn?app_key=asdasasdsad&product_id=001&total_fee=100&app_role_id=001&user_id=001&orde
//r_id=001&app_order_id=001&server_id=001&sign_return=001&sign=fasdasdsadsadsd&time=15020263655&pay_result=1";
//
//        $tRes = sendGet($url);
//
//        print_r($tRes['ret']);


        //下单
        $money = 200;
        $charID = 100001;
        $serverID = 3;
        $source = 0;
        $productId = "com.zen_joy.dragon.payoption_6";
        $rechargeID = 2;
        $orderID = "bingniao_001";
        $receipt = 1;
        $extdata = "";
        $platform = "bingniao";

         //$url = "http://sg.df.baoyugame.com/30002/apple/order.php";
         $url = "http://127.0.0.1:90/pay/bingniao/order.php";
         $data = array("money"=>$money, "charID"=>$charID, "productID"=>$productId,"serverID"=>$serverID,"source"=>0,"rechargeID"=>$rechargeID,"sign"=>'',"platform"=>$platform);
         $strCont = "$MD5_KEY&$source&$serverID&$charID&$rechargeID&$money&$productId&$platform";
         $data['sign'] = md5($strCont);
         $jdata = json_encode($data);
         $tRes = sendPost($url, $jdata);
         print_r(json_decode($tRes['ret'],true));
