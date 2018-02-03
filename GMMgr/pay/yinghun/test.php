<?php
    require_once("../../common.php");

//    $money = 200;
//    $charID = 100001;
//    $serverID = 3;
//    $source = 0;
//    $productId = "com.zen_joy.dragon.payoption_6";
//    $rechargeID = 2;
//    $orderID = "yinghun_001";
//    $receipt = 1;
//    $extdata = "";
//    $platform = "yinghun";
//
//     //$url = "http://sg.df.baoyugame.com/30002/apple/order.php";
//     $url = "http://127.0.0.1:90/pay/yinghun/order.php";
//     $data = array("money"=>$money, "charID"=>$charID, "productID"=>$productId,"serverID"=>$serverID,"source"=>0,"rechargeID"=>$rechargeID,"sign"=>'',"platform"=>$platform);
//     $strCont = "$MD5_KEY&$source&$serverID&$charID&$rechargeID&$money&$productId&$platform";
//     $data['sign'] = md5($strCont);
//     $jdata = json_encode($data);
//     $tRes = sendPost($url, $jdata);
//     print_r(json_decode($tRes['ret'],true));
//
//
//    //回调
//    $app_secret='202cb962234w4ers2aa';
//    $gameOrderNo = "yinghun_5980397c5dc00"; //对应本服务器自己生成的订单号
//    $sdkOrderNo = 111111; //sdk服务器生成的订单号
//    $product = $productId;
//    $userId = $charID;
//
//    $gameID = 1001;
//    $channelID = 1;
//    $appID = 1080;
//    $userID = 100001;
//    $bfOrderID = 101;
//    $channelOrderID = 11;
//    $money = 200;
//    $callbackInfo = "success";
//    $orderStatus = 1;
//    $channelInfo = "channel";
//
//    $time = time();
//
//    $url = "http://127.0.0.1:90/pay/yinghun/callback.php";
//    $data = array(
//        "cpOrderId" => $gameOrderNo,
//        "gameId" => $gameID,
//        "channelId" => $channelID,
//        "appId" => $appID,
//        "userId" => $userID,
//        "bfOrderId" => $bfOrderID ,
//        "channelOrderId" => $channelOrderID ,
//        "money" => $money ,
//        "callbackInfo" => $callbackInfo ,
//        "orderStatus" => $orderStatus ,
//        "channelInfo" => $channelInfo,
//        "time"=>$time
//    );
//    ksort($data);
//    $strSign = "";
//    foreach ($data as $key => $val){
//        $strSign .= $key."=".$val;
//    }
//    $strSign = $strSign.$app_secret;
//    $data['sign'] = md5($strSign);
//    $jdata = json_encode($data);
//    $tRes = sendPost($url, $jdata);
//    //print_r(json_decode($tRes['ret'], true));
//    print_r(json_decode($tRes['ret'],true));



        $gameId = "0001";
        $channelId = "0001";
        $appId = "0001";
        $userId = "0001";
        $sid = "62d1e3be3d8a55cdabfc43786ebc325c";
        $app_secret = "3ecc76c49db7968e142e29d012cd8832";

        $url = "http://127.0.0.1:90/pay/yinghun/yinghun.php";
        $data = array("gameId"=>$gameId, "channelId"=>$channelId, "appId"=>$appId,"sid"=>$sid,"userId" => $userId);
        ksort($data);
        $strSign = "";
        foreach ($data as $key => $val){
            $strSign .= $key."=".$val;
        }
        $strSign = $strSign.$app_secret;
        $data['sign'] = md5($strSign);
        $jdata = json_encode($data);
        $tRes = sendPost($url, $jdata);

        print_r($tRes['ret']);

?>
