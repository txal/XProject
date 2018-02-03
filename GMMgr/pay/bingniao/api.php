<?php
        if(!defined('IN_APP')) exit('Access Denied');

        $app_secret='650821424e78be2541d694d099cdaab1';
        $app_key = '100000203';
        $logFile = "log.txt";


        //返回结果
        function reMessage($ret,$msg,$content) {
            $result = array();
            $result['ret'] = $ret;
            $result['msg'] = $msg;
            $result['content'] = $content;

            echo json_encode($result);
        }

        //订单返回信息
        function orderMessage($ret,$msg,$order_id=0) {
            $result = array();
            $result['ret'] = $ret;
            $result['msg'] = $msg;
            $result['order_id'] = $order_id;

            echo json_encode($result);
        }

        //生成订单
        function order() {
            global $_POST, $_SGLOBAL, $MD5_KEY;
            global $logFile;
            $cont = file_get_contents("php://input");
            $orderID = genUniqueID("bingniao_");
            $param = json_decode($cont, true);
            writeLog("下单:".print_r($param,true)." :$orderID", $logFile);

            $source = $param["source"];
            $serverID = $param["serverID"];
            $charID = $param["charID"];
            $rechargeID = $param["rechargeID"];
            $money = $param["money"];
            $productID = $param["productID"];
            $platform = $param["platform"];

            $strCont = "$MD5_KEY&$source&$serverID&$charID&$rechargeID&$money&$productID&$platform";
            $sign = md5($strCont);
            if ($sign != $param['sign']) {
                writeLog("下单:签名错误 [$strCont]", $logFile);
                return orderMessage("FAIL","签名错误");
            }

            if (!makeOrder($orderID, $source, $serverID, $charID, $money, $rechargeID, $productID)) {
                writeLog("下单:".$_SGLOBAL["mgrdb"]->error(), $logFile);
                return orderMessage("FAIL","插入订单失败");
            }
            return orderMessage("SUCCESS","下单成功",$orderID);
        }

        //获取用户信息接口
        function token() {
            global $_POST,$app_secret,$logFile,$app_key;

//            $cont = file_get_contents("php://input");
//            $param = json_decode($cont, true);

            $authorize_code = $_POST['authorize_code'];

            writeLog("authorize_code:".$authorize_code, $logFile);

            $time = time();

            $url = "https://oauth.ibingniao.com/oauth/token";
            $strCont = "authorize_code=$authorize_code&app_key=$app_key&jh_sign=$app_secret&time=$time";
            $sign = md5($strCont);

            $data = array(
                "app_key" => $app_key,
                "authorize_code" => $authorize_code,
                "sign" => $sign,
                "time" => $time
            );

            $res = sendPost($url, $data);
            $resData = $res['ret'];
            echo $resData;
        }

        //支付结果返回接口
        function callback () {
            global $_GET,$logFile,$app_secret;

            $app_key = $_GET['app_key'];
            $product_id = $_GET['product_id'];
            $total_fee = $_GET['total_fee'];
            $app_role_id = $_GET['app_role_id'];
            $user_id = $_GET['user_id'];
            $order_id = $_GET['order_id'];
            $app_order_id = $_GET['app_order_id'];
            $server_id = $_GET['server_id'];
            $sign = $_GET['sign'];
            $time = $_GET['time'];
            $pay_result = $_GET['pay_result'];

            writeLog("回调:".print_r($_GET, true), $logFile);
            if ($pay_result == 0) {
                writeLog("回调: SDK支付失败 :$order_id", $logFile);
                return reMessage(0,"失败原因","");
            }

            $strSign = "app_key=$app_key&app_order_id=$app_order_id&app_role_id=$app_role_id&order_id=$order_id&pay_result=$pay_result&";
            $strSign .= "product_id=$product_id&server_id=$server_id&total_fee=$total_fee&user_id=$user_id&jh_sign=$app_secret&time=$time";
            $strSign = md5($strSign);

            if ($sign != $strSign) {
                writelog("签名失败：".$sign,$logFile);
                return reMessage(0,"失败原因","");
            }

            $order = queryOrder($order_id);

            if (!$order) {
                writeLog("回调: order not found order:$order_id", $logFile);
                return reMessage(0,"失败原因","");
            }

            $mon = $order['money'];
            if($total_fee != $mon*100){
                writeLog("回调: money not equal :$mon".",".$total_fee, $logFile);
                return reMessage(0,"失败原因","");
            }

            if ($order['state'] != 0) {
                writeLog("回调: state error [$order[state]] order:$order_id", $logFile);
                return reMessage(1,"","");
            }

            if (!updateOrder($order_id, array("state"=>1))) {
                writeLog("回调: update order state fail order:$order_id", $logFile);
                return reMessage(0,"失败原因","");
            }

            writeLog("------充值成功------$order_id", $logFile);
            return reMessage(1,"","");
        }
