<?php
if(!defined('IN_APP')) {
	exit('Access Denied');
}

$_SGLOBAL['i'] = 0;
$_SGLOBAL['block_search'] = $_SGLOBAL['block_replace'] = array();

function parse_template($tpl) {
	global $_SGLOBAL;

	$_SGLOBAL['sub_tpls'] = array($tpl);

	$tplfile = APP_ROOT.'./'.$tpl.'.htm';
	$objfile = APP_ROOT.'./data/tpl_cache/'.str_replace('/','_',$tpl).'.php';

	//read
	$template = sreadfile($tplfile);
	if(empty($template)) {
		exit("Template file : $tplfile Not found or have no access!");
	}

	//模板
	$template = preg_replace_callback("/\<\!\-\-\{template\s+([a-z0-9_\/]+)\}\-\-\>/i", function($matchs) {
		return readtemplate($matchs[1]);
	}, $template);
	//处理子页面中的代码
	$template = preg_replace_callback("/\<\!\-\-\{template\s+([a-z0-9_\/]+)\}\-\-\>/i", function($matchs) {
		return readtemplate($matchs[1]);
	}, $template);
	//解析模块调用
	$template = preg_replace_callback("/\<\!\-\-\{block\/(.+?)\}\-\-\>/i", function($matchs) {
		return blocktags($matchs[1]);
	}, $template);
	//解析广告
	$template = preg_replace_callback("/\<\!\-\-\{ad\/(.+?)\}\-\-\>/i", function($matchs) {
		return adtags($matchs[1]);
	}, $template);
	//时间处理
	$template = preg_replace_callback("/\<\!\-\-\{date\((.+?)\)\}\-\-\>/i", function($matchs) {
		return datetags($matchs[1]);
	}, $template);
	//头像处理
	$template = preg_replace_callback("/\<\!\-\-\{avatar\((.+?)\)\}\-\-\>/i", function($matchs) {
		return avatartags($matchs[1]);
	}, $template);
	//PHP代码
	$template = preg_replace_callback("/\<\!\-\-\{eval\s+(.+?)\s*\}\-\-\>/is", function($matchs) {
		$res = evaltags($matchs[1]);
		return $res;
	}, $template);

	//开始处理
	//变量
	$var_regexp = "((\\\$[a-zA-Z_\x7f-\xff][a-zA-Z0-9_\x7f-\xff]*)(\[[a-zA-Z0-9_\-\.\"\'\[\]\$\x7f-\xff]+\])*)";
	$template = preg_replace("/\<\!\-\-\{(.+?)\}\-\-\>/s", "{\\1}", $template);
	$template = preg_replace("/([\n\r]+)\t+/s", "\\1", $template);
	$template = preg_replace("/(\\\$[a-zA-Z0-9_\[\]\'\"\$\x7f-\xff]+)\.([a-zA-Z_\x7f-\xff][a-zA-Z0-9_\x7f-\xff]*)/s", "\\1['\\2']", $template);
	$template = preg_replace("/\{(\\\$[a-zA-Z0-9_\[\]\'\"\$\.\x7f-\xff]+)\}/s", "<?=\\1?>", $template);
	
	$template = preg_replace_callback("/$var_regexp/s", function($matchs) {
		return addquote('<?='.$matchs[1].'?>');
	}, $template);
	
	$template = preg_replace_callback("/\<\?\=\<\?\=$var_regexp\?\>\?\>/s", function($matchs) {
		return addquote('<?='.$matchs[1].'?>');
	}, $template);
	
	//逻辑
	$template = preg_replace_callback("/\{elseif\s+(.+?)\}/is", function($matchs) {
		return stripvtags('<?php } elseif('.$matchs[1].') { ?>','');
	}, $template);
	
	$template = preg_replace("/\{else\}/is", "<?php } else { ?>", $template);
	//循环
	
	for($i = 0; $i < 5; $i++) {
		$template = preg_replace_callback("/\{loop\s+(\S+)\s+(\S+)\}(.+?)\{\/loop\}/is", function($matchs) {
			return stripvtags('<?php if(is_array('.$matchs[1].')) { foreach('.$matchs[1].' as '.$matchs[2].') { ?>',$matchs[3].'<?php } } ?>');
		}, $template);
		$template = preg_replace_callback("/\{loop\s+(\S+)\s+(\S+)\s+(\S+)\}(.+?)\{\/loop\}/is", function($matchs) {
			return stripvtags('<?php if(is_array('.$matchs[1].')) { foreach('.$matchs[1].' as '.$matchs[2].' => '.$matchs[3].') { ?>',$matchs[4].'<?php } } ?>');
		}, $template);
		$template = preg_replace_callback("/\{if\s+(.+?)\}(.+?)\{\/if\}/is", function($matchs) {
			return stripvtags('<?php if('.$matchs[1].') { ?>',$matchs[2].'<?php } ?>');
		}, $template);
	}
	
	//常量
	$template = preg_replace("/\{([a-zA-Z_\x7f-\xff][a-zA-Z0-9_\x7f-\xff]*)\}/s", "<?=\\1?>", $template);

	//替换
	if(!empty($_SGLOBAL['block_search'])) {
		$template = str_replace($_SGLOBAL['block_search'], $_SGLOBAL['block_replace'], $template);
	}

	//换行
	$template = preg_replace("/ \?\>[\n\r]*\<\? /s", " ", $template);

	//附加处理
	$template = "<?php if(!defined('IN_APP')) exit('Access Denied');?><?php subtplcheck('".implode('|', $_SGLOBAL['sub_tpls'])."', '$_SGLOBAL[timestamp]', '$tpl');?>$template<?php ob_out();?>";

	if(!swritefile($objfile, $template)) {
		exit("File: $objfile can not be write!");
	}
}

function addquote($var) {
	return str_replace("\\\"", "\"", preg_replace("/\[([a-zA-Z0-9_\-\.\x7f-\xff]+)\]/s", "['\\1']", $var));
}

function striptagquotes($expr) {
	$expr = preg_replace("/\<\?\=(\\\$.+?)\?\>/s", "\\1", $expr);
	$expr = str_replace("\\\"", "\"", preg_replace("/\[\'([a-zA-Z0-9_\-\.\x7f-\xff]+)\'\]/s", "[\\1]", $expr));
	return $expr;
}

function evaltags($php) {
	global $_SGLOBAL;

		$f = fopen('./log.txt', 'a');
		fwrite($f, "\n$php\n");
		fclose($f);
		
	$_SGLOBAL['i']++;
	$search = "<!--EVAL_TAG_{$_SGLOBAL['i']}-->";
	$_SGLOBAL['block_search'][$_SGLOBAL['i']] = $search;
	$st = preg_replace("/\<\?\=(\\\$.+?)\?\>/s", "\\1", $php);
	$_SGLOBAL['block_replace'][$_SGLOBAL['i']] = "<?php ".$st." ?>";
	return $search;
}

function stripvtags($expr, $statement='') {
	$oldexpr = $expr;
	$expr = str_replace("\\\"", "\"", preg_replace("/\<\?\=(\\\$.+?)\?\>/s", "\\1", $expr));
	$statement = str_replace("\\\"", "\"", $statement);
	return $expr.$statement;
}

function readtemplate($name) {
	global $_SGLOBAL, $_SC;

	$tpl = strexists($name,'/')?$name:"template/$_SC[template]/$name";

	$_SGLOBAL['sub_tpls'][] = $tpl;
	$file = APP_ROOT.'./'.$tpl.'.htm';
	$content = sreadfile($file);
	return $content;
}
?>