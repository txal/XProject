<?php
    header("Content-type: text/html; charset=utf-8");
    /*
     * Created on 2015-9-1
     *
     * To change the template for this generated file go to
     * Window - Preferences - PHPeclipse - PHP - Code Templates
     */
	//下单
    $_POST["uid"] = 10123059;
    $_POST["money"] = 2;
    $_POST["platform"] = "test";
    $_POST["channel"] = "test";
    $_POST["area_id"] = "1001";
    $_POST["extend"] = "test";
    $_POST["productId"] = "com";
    $_POST['waresid'] = 1;
    //require_once("order.php");

    $_POST["transdata"]='{"appid":"3003686553","appuserid":"10123059","cporderid":"1234qwedfq2as123sdf3f1231234r","cpprivate":"11qwe123r23q232111","currency":"RMB","feetype":0,"money":0.12,"paytype":403,"result":0,"transid":"32011601231456558678","transtime":"2016-01-23 14:57:15","transtype":0,"waresid":1}';
    $_POST["sign"]="jeSp7L6GtZaO/KiP5XSA4vvq5yxBpq4PFqXyEoktkPqkE5b8jS7aeHlgV5zDLIeyqfVJKKuypNUdrpMLbSQhC8G4pDwdpTs/GTbDw/stxFXBGgrt9zugWRcpL56k9XEXM5ao95fTu9PO8jMNfIV9mMMyTRLT3lCAJGrKL17xXv4=";
    $_POST["signtype"]='RSA';
    require_once("callback.php");
?>
