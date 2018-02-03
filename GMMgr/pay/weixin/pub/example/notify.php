<?php
ini_set('date.timezone','Asia/Shanghai');
error_reporting(E_ERROR);

require_once '../../../../common.php';
require_once "../lib/WxPay.Api.php";
require_once '../lib/WxPay.Notify.php';
require_once 'log.php';

//初始化日志
$logHandler= new CLogFileHandler("../logs/".date('Y-m-d').'.log');
$log = Log::Init($logHandler, 15);

class PayNotifyCallBack extends WxPayNotify
{
	//查询订单
	public function Queryorder($transaction_id)
	{
		$input = new WxPayOrderQuery();
		$input->SetTransaction_id($transaction_id);
		$result = WxPayApi::orderQuery($input);
		Log::DEBUG("query:" . json_encode($result));
		if(array_key_exists("return_code", $result)
			&& array_key_exists("result_code", $result)
			&& $result["return_code"] == "SUCCESS"
			&& $result["result_code"] == "SUCCESS")
		{
			return true;
		}
		return false;
	}
	
	//重写回调处理函数
	public function NotifyProcess($data, &$msg)
	{
		Log::DEBUG("call back:" . json_encode($data));
		$notfiyOutput = array();
		
		if(!array_key_exists("transaction_id", $data)){
			$msg = "输入参数不正确";
			return false;
		}
		//查询订单，判断订单真实性
		if(!$this->Queryorder($data["transaction_id"])){
			$msg = "订单查询失败";
			return false;
		}

		//后台处理
		$orderID = strval($data['out_trade_no']);
		$money = doubleval($data['total_fee']);
		$row = queryOrder($orderID);
		if (!$row) {
			$msg = "订单不存在";
			Log::ERROR("call back order not exist: $orderID");
			return false;
		}
		$mgrMoney = doubleval($row['money'])*100;
		if ($money != $mgrMoney) {
			$msg = "金额不正确";
			Log::ERROR("call back money error: $orderID wx:[$money] mgr:[$mgrMoney]");
			return false;
		}
		$state = intval($row['state']);
		if ($state != 0) {
			Log::ERROR("call back state error: $orderID state:[$state]");
			return true;
		}
		$dbField = array("state"=>1);
		if (!updateOrder($orderID, $dbField)) {
			Log::ERROR("call back update order error: $orderID");
			return false;
		}
		Log::INFO("------------充值成功-----------: $orderID");
		return true;
	}
}

Log::DEBUG("begin notify");
$notify = new PayNotifyCallBack();
$notify->Handle(false);
