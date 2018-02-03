<?php
require_once 'common.php';

header("content-type:text/html;charset=gb2312");

if (isset($_POST['action']) && $_POST['action'] == 'query') {
	$query = trim($_POST['query']);
	if (empty($query)) {
		alert("No sql for mysql to execute!");
	}
	
	if ($result = $_SGLOBAL['mgrdb']->query(dstripslashes($query))) {
		
echo <<< STYLE
<style>
	* {
		font-size: 13px;
		font-family: "Courier New", Courier, monospace;
	}
	table {
		border:1px solid #000;
	}
	table td {
		border:1px solid #000;
	}
</style>
STYLE;
		
		if (($selectTable = !strncasecmp($query, "select", 6)) ||
			($showTables = !strncasecmp($query, "show tables", 11)) ||
			($showDatabases = !strncasecmp($query, "show databases", 14))
		) {
			if ($selectTable) {
				$fields = $_SGLOBAL['mgrdb']->num_fields($result);
				
				echo "\n<table>\n<tr style='background:#EEE;'>\n";
				for ($i = 0; $i < $fields; $i++) {
					$fieldobj = $_SGLOBAL['mgrdb']->fetch_fields($result);
					printf("\t<td>%s</td>\n", $fieldobj->name);
				}
				echo "</tr>\n";
				
				while ($row = $_SGLOBAL['mgrdb']->fetch_row($result)) {
					echo "<tr>\n";
					foreach ($row as $value) {
						printf("\t<td>%s</td>\n", (empty($value) ? '&nbsp;' : $value));
					}
					echo "</tr>\n";
				}

				printf("</table>\n<div>[<a href='javascript:history.back();'>Back</a>]</div>");
				
			} else {
				printf("<h3>%s</h3>\n<ul>\n", ($showTables) ? "Tables" : "Databases");
				while ($row = $_SGLOBAL['mgrdb']->fetch_row($result)) {
					printf("<li>%s</li>\n", $row[0]);
				}
				printf("</ul>\n<div>[<a href='javascript:history.back();'>Back</a>]</div>");
			}
		} else {
			alert("execute success!");
		}
		
	} else {
		alert("execute failure!");
	}
	
} else {
?>
<div>
	<h3>SQL for execute:</h3>
	<form action="mysql_query.php" method="post">
	<p><textarea name="query" style="width:350px;height:100px;"></textarea></p>
	<p><input type="hidden" name="action" value="query" /><input type="submit" value="QUERY" /></p>
	</form>
</div>
<?php
}
function dstripslashes($string) {
	if(is_array($string)) {
		foreach($string as $key => $val) {
			$string[$key] = $this->dstripslashes($val);
		}
	} else {
		$string = stripslashes($string);
	}
	return $string;
}

function alert($message) {
	exit("<script>alert('$message');history.back();</script>");
}
?>