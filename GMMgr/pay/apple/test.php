<?php
    require_once("../../common.php");
    require_once("api.php");


     $money = 200;
     $charID = 100001;
     $serverID = 3;
     $source = 0;
     $productId = "com.zen_joy.dragon.payoption_6";
     $rechargeID = 2;
     $platform = "ios";

     $url = "http://127.0.0.1:90/pay/apple/order.php";
     $data = array("money"=>$money, "charID"=>$charID, "productID"=>$productId,"serverID"=>$serverID,"source"=>0,"rechargeID"=>$rechargeID,"sign"=>'',"platform"=>$platform);
     $strCont = "$MD5_KEY&$source&$serverID&$charID&$rechargeID&$money&$productId&$platform";
     $data['sign'] = md5($strCont);
     $jdata = json_encode($data);
     $tRes = sendPost($url, $jdata);
     print_r(json_decode($tRes['ret'],true));



    //回调
//    $gameOrderNo = "apple_583ced6cce721"; //对应本服务器自己生成的订单号
//    $sdkOrderNo = 111111; //sdk服务器生成的订单号
//    $product = $productId;
//    $userId = $uid;
//    $sign = "";
//    $time = time();

    // $url = "http://sg.df.baoyugame.com/30002/apple/callback.php";
    // $data = array("gameOrderNo"=>$gameOrderNo, "orderNo"=>$sdkOrderNo, "product"=>$product, "sign"=>$sign, "time"=>$time, "extend"=>$extend, "userId"=>$userId);
    // $tRes = sendPost($url, $data);
    // print_r($tRes);


    //回调
    $gameOrderNo = "apple_59b5f6e1c8e1b "; //对应本服务器自己生成的订单号
    $sdkOrderNo = 111111; //sdk服务器生成的订单号
    $product = $productId;
    $userId = 111;
    $sign = "";
    $time = time();

    $url = "http://sg.df.baoyugame.com/30002/apple/callback.php";
    $data = array("gameOrderNo"=>$gameOrderNo, "orderNo"=>$sdkOrderNo, "product"=>$product, "time"=>$time, "userId"=>$userId);
    $tRes = sendPost($url, $data);
    print_r($tRes);

    //apple验证
    $receipt = "";
    $sandbox = "";
    $inAppTransID = "";
    $inAppProduct = "";
    print(appleReceiptVerify(false, $gameOrderNo, "receipt",$inAppProduct, $inAppTransID, $sandbox));


?>
