<?php
header("Content-type:text/html;charset=utf8");
function request($serverID, $method, $data="", $ret=true) {
	$ret = true; //不能是false

	//服务器信息
	global $_SERVERLIST;
	$gm = $_SERVERLIST[$serverID]['gm'];
	$ip = $gm['ip'];
	$port = $gm['port'];

	//memberinfo
	//取出当前页的用户ID
	$data = array("method"=>$method, "data"=>$data);
	$data = json_encode($data);
	$cmd = 50001;
	$fp = fsockopen($ip, $port, $errno, $errstr, 3);
	// Resource id #11----资源标识
	//socket
	if (!$fp) {
		echo "<h1 style='color:red;'>连接服务器失败:$errstr</h1>";
		exit();
	}

	/*------2------*/
    //组二进制数据包   长度+数据+包头
	//发送到游戏服务器，游戏服务器会根据这个格式解码出来进行数据处理
    $dataSize = strlen($data); //获取数据的长度
	$packetSize = 4 + $dataSize + 8; //str_len + str_cont + header
	$packet = pack("iia{$dataSize}", $packetSize, $dataSize, $data); //data
	$packet .= pack("vccI", $cmd, -1, 0, 0); //header


    /*------3------*/
	$retData = array();
	fwrite($fp, $packet, $packetSize + 4);
	if ( $ret ) {
		if (!feof($fp)) {
			$buffer = fread($fp, 8);
			$array = unpack("ilen/islen", $buffer);
			$packetSize= $array['len'];
			$dataSize = $array["slen"];
			if($dataSize > 0) {
				$buffer = fread($fp, $dataSize);
				$result = unpack("a{$dataSize}data", $buffer);
				$retData = json_decode($result["data"], true);
			}
		}
	}
	fclose($fp);

	if (empty($retData["data"]) && !empty($retData["error"])) {
		echo "<h1 style='color:red;'>request: $retData[error]</h1>";
	}
	if (!empty($retData["data"])) {
		return $retData["data"];
	}
	return array();
}

?>
