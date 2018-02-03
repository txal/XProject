<?php

        require_once 'common.php';
        isaccess("PLAYJOINQUERY") or exit('Access Denied');

        $stime = "";
        $etime = "";

        include template("playjoin_query");

?>