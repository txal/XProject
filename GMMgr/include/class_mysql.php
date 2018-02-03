<?php

if(!defined('IN_APP'))
{
	exit('Access Denied');
}

class dbstuff
{
	var $querynum = 0;
	var $link;
	var $charset;
	function connect($dbhost, $dbuser, $dbpw, $dbname='', $dbport=3306, $halt=TRUE)
	{

	    $this->link = mysqli_init(); 
		$this->link->options(MYSQLI_OPT_CONNECT_TIMEOUT,2); //2秒失败
		if (!@$this->link->real_connect($dbhost, $dbuser, $dbpw, $dbname, $dbport))
		{
			$halt && $this->halt("Can not connect to MySQL server: [$dbhost] [$dbuser] [$dbpw] [$dbname]");
			return false;
		}
		if ($this->charset)
		{
			$this->link->set_charset($this->charset);
		}
		return true;
	}

	function select_db($dbname)
	{
		return $this->link->select_db($dbname);
	}

	function fetch_array($query, $result_type = "MYSQL_ASSOC")
	{
		if(!empty($query))
		{
			if ($result_type == "MYSQL_ASSOC") {
				return $query->fetch_assoc();
			}
			return $query->fetch_array();
		}
		return null;
	}

	function query($sql, $type = '')
	{
		if(!($query = $this->link->query($sql)) && $type != 'SILENT')
		{
			$this->halt('MySQL Query Error', $sql);   
		}
		$this->querynum++;
		return $query;
	}

	function affected_rows()
	{
		return $this->link->affected_rows;
	}

	function error()
	{
		$error = $this->link ? $this->link->error : "";
		return iconv("GBK", "UTF-8", $error);
	}

	function errno()
	{
		return $this->link ? $this->link->errno : 0;
	}

	function num_rows($query)
	{
		return $query->num_rows;
	}

	function num_fields($query)
	{
		return $query->num_fields;
	}

	function free_result($query)
	{
		return $query->free();
	}

	function insert_id()
	{
		return $this->link->insert_id;
	}

	function fetch_row($query)
	{
		return $query->fetch_row();
	}

	function fetch_fields($query)
	{
		return $query->fetch_fields();
	}

	function version()
	{
		return $this->link->server_info;
	}

	function close()
	{
		return $this->link->close();
	}

	function halt($message = '', $sql = '')
	{
		$dberror = $this->error();
		$dberrno = $this->errno();
		echo "<div style=\"position:absolute;bottom:10px;font-size:11px;font-family:verdana,arial;background:#EBEBEB;padding:0.5em;\">
				<b>MySQL Error</b><br>
				<b>Message</b>: $message<br>
				<b>SQL</b>: $sql<br>
				<b>Error</b>: $dberror<br>
				<b>Errno.</b>: $dberrno<br>
				</div>";
		exit();
	}
}

?>
