 <?php
 	 require_once '../common.php';
	 require_once 'autoload.php';
	 // 引入鉴权类
	 use Qiniu\Auth;
	 // 引入上传类
	 use Qiniu\Storage\UploadManager;
	 // 需要填写你的 Access Key 和 Secret Key
	 $accessKey = 'bTwUzEhQgft8mWMdsnVSpenhapdx0Ga-XTveVCK1';
	 $secretKey = 'rnLoNZM5oy8dswWldsGDcYc_ijWP6DrV4tpLLJ4S';
	 // 构建鉴权对象
	 $auth = new Auth($accessKey, $secretKey);
	 // 要上传的空间
	 $bucket = 'bucket_chess';
	 // 生成上传 Token
	 $token = $auth->uploadToken($bucket);
	 echo "$token";
?>
