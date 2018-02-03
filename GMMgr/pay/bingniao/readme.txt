下单(POST方式)============：
http://sg.df.baoyugame.com/bingniao/order.php
参数(json串)：
source：渠道ID
serverID：服务器ID
charID：角色ID
rechargeID：充值商品配置ID
money：人民币
productID：IOS商品标识
platform：平台(ios/android)
sign：签名

签名方式：
组合字符串：MD5_KEY&source&serverID&charID&rechargeID&money&productID&platform
生成签名: md5(组合字符串)
MD5_KEY：6XJRju


回调=============：
http://sg.df.baoyugame.com/bingniao/callback.php


用户会话验证============：
http://sg.df.baoyugame.com/bingniao/token.php
参数(json串)：
authorize_code: 应用客户端返回的临时通行码

成功返回：
       {
       content = {
       "access_token" = 296ebf9ca90afcde08aa8d743ec5d01e;
       expires = 2592000;
       "user_id" = 88027;
       "user_name" = Lizhiwei5;
       };
       msg = "";
       ret = 1;
       }


失败返回：
        {
        "ret":0,
        "msg":"\u672a\u627e\u5230\u5bf9\u5e94\u7684",
        "content":"",
        }