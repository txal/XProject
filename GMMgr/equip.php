<?php
require_once 'common.php';
header("content-type:text/html;charset=$_SC['charset']");

if (!isaccess("ARM")) {
	exit('Access Denied');
}

$page = !empty($_GET['page']) ? intval($_GET['page']) : 1;

if (!empty($_GET)) {
	$searchType = isset($_GET['searchType']) ? $_GET['searchType'] : exit('Access Denied');
	$searchText = isset($_GET['searchText']) ? $_GET['searchText'] : exit('Access Denied');
	$total      = !empty($_GET['total'])     ? intval($_GET['total']) : 0;

	$where = NULL;
	switch ($searchType) {
	case '2':
	case '3':
		$searchText = intval($searchText);
		break;
	case '1':
	case '4':
		if($page == 1 )
			$searchText = '"'.$searchText.'"';
		break;
	default:
		break;
	}

$lua = <<<LUA
do
	DoFun("QUERYARM", $searchType, $searchText, $page, 50, $total)
end
LUA;

echo " do func is ". $lua;
	eval('$record = '.query_cmd(101, $lua));
	
	if ($total == 0) {
		$total = array_pop($record);
	} else {
		array_pop($record);		
	}
	
	$url = "?searchType=$searchType&searchText=". urlencode($searchText). "&total=$total";
	$pagelist = multi($total, 50, $page, $url);
	
} else {

	$record = array();
	$pagelist = '';
}

include template('equip');
?>