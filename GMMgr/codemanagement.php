<?php
        require_once 'common.php';
        include_once('./include/PHPExcel18/PHPExcel-1.8/Classes/PHPExcel.php');
        isaccess("CODEMANAGEMENT") or exit('Access Denied');
        if(empty($_GET['action'])){
            dbConnect("mgrdb");

            $onlineCount = 0;
            $curPage = 1;
            $pageSize = 40;
            if (!empty($_GET["page"])) {
                $curPage = $_GET["page"];
            }

            $cType = array();
            $sID = empty($_GET['sid']) ? "" : intval($_GET['sid']);

            $codeTypeData = sqlQuery("cdkeytype",$pageSize,$curPage);
            $codeTypeTotal = $codeTypeData["total"];
            $codeTypeQuery = $codeTypeData["query"];
            $codeType = codeTypeList($codeTypeQuery);
            $multi = multi($codeTypeTotal, $pageSize, $curPage, "codemanagement.php");

            $keyCodeData = sqlQuery("cdkeycode",$pageSize,$curPage);
            $keyCodeTotal = $keyCodeData["total"];
            $keyCodeQuery = $keyCodeData["query"];
            $keyCode = codeList($keyCodeQuery);
            $multi2 = multi($keyCodeTotal, $pageSize, $curPage, "codemanagement.php");

            //查找所选服务器对应兑换码类型
            if (empty($sID)) {
                $cType = array();
            } else {
                $sql = "SELECT name,id FROM cdkeycode JOIN cdkeytype WHERE cdkeycode.giftid=cdkeytype.id AND cdkeycode.`server`=$sID GROUP BY name";
                $query = $_SGLOBAL["mgrdb"] -> query($sql);
                while ($row = $_SGLOBAL["mgrdb"] -> fetch_array($query)) {
                    array_push($cType,$row);
                }
            }



        } else if(!empty($_GET["action"]) && $_GET["action"] == "updateCode"){
            $db = $_SGLOBAL["mgrdb"];
            $id = intval($_GET['id']);
            $name = strval($_GET['name']);
            $starttime = intval(strtotime($_GET['starttime']));
            $endtime = intval(strtotime($_GET['endtime']));
            $award = strval($_GET['award']);
            $desc = empty($_GET['desc']) ? "" : strval($_GET['desc']);
            $query = $db->query("update cdkeytype set name = '$name',starttime = '$starttime',endtime = '$endtime',award = '$award',`desc` = '$desc' where id = $id;");
            $result = $query>=0 ? "SUCCESS" : "FALSE";
            echo $result;
            exit();

        } else if(!empty($_GET["action"]) && $_GET["action"] == "addCodeType"){
            $db = $_SGLOBAL["mgrdb"];
            $name = strval($_GET['name']);
            $starttime = intval(strtotime($_GET['starttime']));
            $endtime = intval(strtotime($_GET['endtime']));
            $award = strval($_GET['award']);
            $desc = empty($_GET['desc']) ? "" : strval($_GET['desc']);
            $keyType = empty($_GET['keyType']) ? 0 : intval($_GET['keyType']);
            $query = $db->query("insert into cdkeytype set name='$name',starttime=$starttime,endtime=$endtime,award='$award',`desc`='$desc',type=$keyType;");
            $result = $query>=0 ? "SUCCESS" : "FALSE";
            echo $result;
            exit();

        } else if(!empty($_GET["action"]) && $_GET["action"] == "createKey"){
            $db = $_SGLOBAL["mgrdb"];
            $serverID = empty($_GET['serverID']) ? -1 : intval($_GET['serverID']);
            $codeType = empty($_GET['codeType']) ? 0 : intval($_GET['codeType']);
            $keyCount = empty($_GET['keycount']) ? 0 : intval($_GET['keycount']);

            $num = 0;
            while ($num < $keyCount){
                $key = uniqid("",true);
                $key = str_replace('.','',strval($key));
                $key = substr(md5($key),8,16);
                $query = $db->query("insert into cdkeycode set server=$serverID,giftid=$codeType,charlist='[]',`key`='$key'");
                $keyCount --;
            }
            $result = $query ? "SUCCESS" : "FALSE";
            echo $result;
            exit();

        } else if(!empty($_GET["action"]) && $_GET["action"] == "delAward"){
            $db = $_SGLOBAL["mgrdb"];
            $serverID = empty($_GET['awardID']) ? 0 : intval($_GET['awardID']);
            $delType = $db->query("delete from cdkeytype where id = $serverID");
            $delData = $db->query("delete from cdkeycode where giftid = $serverID");
            $result = ($delType && $delData) ? "SUCCESS" : "FALSE";
            echo $result;
            exit();

        } else if(!empty($_GET["action"]) && $_GET["action"] == "exportCode") {
            $db = $_SGLOBAL["mgrdb"];
            $sid = intval($_GET['sid']);
            $ktype = intval($_GET['ktype']);
            $resArray = array();

            $sql = "SELECT `key`,name,servername,charlist,cdkeycode.time ";
            $sql .= "FROM cdkeycode ";
            $sql .= "JOIN cdkeytype ON cdkeycode.giftid = cdkeytype.id JOIN serverlist ON cdkeycode.`server` = serverlist.serverid ";
            $sql .= "WHERE `server`=$sid AND giftid=$ktype";

            $query = $db -> query($sql);
            while ($row = $db -> fetch_array($query)) {
                array_push($resArray,$row);
            }

            //创建对象
            $excel = new PHPExcel();

            //Excel表格式,这里简略写了8列
            $letter = array('A','B','C','D','E');

            //表头数组
            $tableheader = array('兑换码','礼包名','服务器','兑换玩家','兑换时间');

            //设置文本垂直居中
            foreach ($letter as $val) {
                $excel->getActiveSheet()->getStyle($val)->getAlignment()->setHorizontal(\PHPExcel_Style_Alignment::HORIZONTAL_CENTER);
            }

            //填充表头信息
            for($i = 0;$i < count($tableheader);$i++) {
                $excel->getActiveSheet()->setCellValue("$letter[$i]1","$tableheader[$i]");
                $excel->getActiveSheet()->getDefaultColumnDimension($i)->setWidth(25);
            }

            //填充表格信息
            for ($i = 2;$i <= count($resArray) + 1;$i++) {
                $j = 0;
                foreach ($resArray[$i - 2] as $key=>$value) {
                    $excel->getActiveSheet()->setCellValue("$letter[$j]$i","$value");
                    $j++;
                }
            }

            //创建Excel输入对象
            $write = new PHPExcel_Writer_Excel5($excel);
            header("Pragma: public");
            header("Expires: 0");
            header("Cache-Control:must-revalidate, post-check=0, pre-check=0");
            header("Content-Type:application/force-download");
            header("Content-Type:application/vnd.ms-execl");
            header("Content-Type:application/octet-stream");
            header("Content-Type:application/download");;
            header('Content-Disposition:attachment;filename="code.xls"');
            header("Content-Transfer-Encoding:binary");
            $write->save('php://output');

            exit();
        } else if (!empty($_GET["action"]) && $_GET["action"] == "search") {
            global $_SGLOBAL;
            $db = $_SGLOBAL["mgrdb"];
            $serverID = intval($_GET['serverID']);
            $codeType = intval($_GET['codeType']);
            if (!empty($serverID) && empty($codeType)) {
                $sql = "SELECT * FROM cdkeycode JOIN cdkeytype WHERE cdkeycode.giftid=cdkeytype.id AND server=$serverID ORDER BY server,giftid";
                $query = $_SGLOBAL["mgrdb"]->query($sql);
            } else if(empty($serverID) && !empty($codeType)) {
                $sql = "SELECT * FROM cdkeycode JOIN cdkeytype WHERE cdkeycode.giftid=cdkeytype.id AND giftid=$codeType ORDER BY server,giftid";
                $query = $_SGLOBAL["mgrdb"]->query($sql);
            } else {
                $sql = "SELECT * FROM cdkeycode JOIN cdkeytype WHERE cdkeycode.giftid=cdkeytype.id AND server=$serverID AND giftid=$codeType ORDER BY server,giftid";
                $query = $_SGLOBAL["mgrdb"]->query($sql);
            }

            $keyCode = codeList($query);
            echo json_encode($keyCode);
            exit();
        }

        function sqlQuery($table,$pageSize,$curPage){
            global $_SGLOBAL;
            $query = $_SGLOBAL["mgrdb"]->query("select count(1) as total from $table;");
            $row = $_SGLOBAL["mgrdb"]->fetch_array($query);
            $total = $row["total"];
            $begin = ($curPage - 1) * $pageSize;
            if($table=="cdkeycode"){
                $query = $_SGLOBAL["mgrdb"]->query("select * from $table join cdkeytype where $table.giftid=cdkeytype.id order by server,giftid limit $begin,$pageSize;");
            }else{
                $query = $_SGLOBAL["mgrdb"]->query("select * from $table order by id asc limit $begin,$pageSize;");
            }

            $data = array("total"=>$total,"query"=>$query);
            return $data;
        }

        //兑换码类型列表
        function codeTypeList($query){
            global $_SGLOBAL;
            $codes = array();
            while($row = $_SGLOBAL['mgrdb']->fetch_array($query)){
                $code = array();
                $code['id'] = $row['id'];
                $code['name'] = $row['name'];
                $code['starttime'] = makeStrTime($row['starttime']);
                $code['endtime'] = makeStrTime($row['endtime']);
                $code['award'] = $row['award'];
                $code['desc'] = $row['desc'];
                $code['type'] = "";
                if($row['type'] == 1){
                    $code['type'] = "神秘宝箱";
                } else if($row['type'] == 2){
                    $code['type'] = "多人一KEY";
                } else if($row['type'] == 3){
                    $code['type'] = "一人多KEY";
                } else {
                    $code['type'] = "一人一KEY";
                }
                array_push($codes,$code);
            }
            return $codes;
        }

        //兑换码列表
        function codeList($query){
            global $_SGLOBAL;
            $codes = array();
            while($row = $_SGLOBAL['mgrdb']->fetch_array($query)){
                $code = array();
                $code['key'] = $row['key'];
                $code['name'] = $row['name'];
                if($row['server']==0){
                    $code['server'] = "全服";
                }else{
                    $q = $_SGLOBAL["mgrdb"]->query("select * from serverlist join cdkeycode on serverlist.serverid=cdkeycode.server and cdkeycode.server=$row[server]");
                    while($row2 = $_SGLOBAL["mgrdb"]->fetch_array($q)){
                        $code['server'] = $row2['servername'];
                    }
                }
                $code['charlist'] = $row['charlist'];
                $code['time'] = $row['time'];
                array_push($codes,$code);
            }
            return $codes;
        }

        include template("codemanagement");