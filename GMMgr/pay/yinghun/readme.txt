下单(POST方式)============：
http://sg.df.baoyugame.com/yinghun/order.php
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
http://sg.df.baoyugame.com/yinghun/callback.php


用户会话验证============：
http://sg.df.baoyugame.com/yinghun/yinghun.php
参数(json串)：
gameId: 游戏ID
channelId: 渠道ID
appId: 游戏包ID
userId: 用户ID
sid: Sid(登录后从SDK获取的sid),

成功返回：
        ret: 0,
        msg: 成功,
        content: {
            data: {
            gameId: **,
            channelId: **,
            appId: **,
            userId: **,
            sdkData: {
            channelUid: **
                  }
                }
         }


失败返回：
        {
          ret: 1,
          msg: 失败,
          content: {}
        }





