var count = 0;
function malert(str)
{
	if(count > 10 )
	{
		return;
	}else
	{
		alert(str);
		count = count + 1 ;
	}
};
//-----------------------------------
function MTime()
{
	this.value = 2;	
	this.panel = this.getElementById("__timePanel");
	this.iframe = window.frames["__timeIframe"];
	this.parentControl = null;
	
	this.date = new Date();
	this.hour = this.date.getHours();
	this.minute = this.date.getMinutes();
	this.second = this.date.getSeconds();
};

MTime.language = {
	"hour"	 : ["\u65F6"],
	"minute" : ["\u5206"],
	"second" : ["\u79D2"],
};

MTime.prototype.getElementById = function(id)
{
	return document.getElementById(id);
};

MTime.prototype.format = function(string)
{
	var args = arguments;
	var pattern = new RegExp("%[0-9]*[ds]","g");
	var counter = 1;
	return String(string).replace(pattern, 
		function(match, index)
		{
			counter = counter + 1 ;
			var iv = parseInt(args[counter -1 ]);	
			if(iv < 10)
			{
				return "0" + iv;
			}else{
				return iv;
			}
		}
	);
};

MTime.prototype.update = function(e)
{
	this.hour  	= e.form.hourSelect.options[e.form.hourSelect.selectedIndex].value;
	this.minute	= e.form.minuteSelect.options[e.form.minuteSelect.selectedIndex].value;
	this.second	= e.form.secondSelect.options[e.form.secondSelect.selectedIndex].value;
	
	var value = this.format("%2d:%2d:%2d",this.hour, this.minute, this.second);
	this.parentControl.value = value;
};

MTime.prototype.draw = function()
{
	mtime = this;

	var _cs = [];
	_cs[_cs.length] = '<form id="__timeForm" name="__timeForm" method="post">';
	_cs[_cs.length] = '<table width="100%" border="0" cellpadding="0" cellspacing="1" align="left">';
	_cs[_cs.length] = '<tr>';
	_cs[_cs.length] = '<td align="left" style="border-right:1px solid"><select id="hourSelect" name="hourSelect" style="border:none;"><\/select><\/div><\/td>';
	_cs[_cs.length] = '<td align="left" style="border-right:1px solid"><div><select id="minuteSelect" name="minuteSelect" style="border:none;"><\/select><\/div><\/td>';
	_cs[_cs.length] = '<td align="left"><div><select id="secondSelect" name="secondSelect" style="border:none;"><\/select><\/div><\/td>';
	_cs[_cs.length] = '<\/tr>';
	_cs[_cs.length] = '<\/table>';
	
	//存贮全局变量
	this.iframe.document.body.innerHTML = _cs.join("");
	this.form = this.iframe.document.forms["__timeForm"];
	
	//绑定事件
	this.form.hourSelect.onchange = function () 
	{
		mtime.update(this);
	};
	
	this.form.minuteSelect.onchange = function () 
	{
		mtime.update(this);
	};
	
	this.form.secondSelect.onchange = function () 
	{
		mtime.update(this);
	};

};

MTime.prototype.bindHour = function()
{
	var hr 		= this.form.hourSelect;
	hr.length	= 0 ;
	
	var hourList=['00','01','02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','19','20','21','22','23'];	
	for( var i  = 0; i< 24; i++)
	{
		var hstr = hourList[i];
		var hlg  = MTime.language["hour"][0];
		hr.options[hr.length] = new Option( hstr + hlg, i );
	}
};

MTime.prototype.bindMinute = function()
{
	var mt 		= this.form.minuteSelect;
	mt.length	= 0 ;
	
	var minuteList 	=['00','01','02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','19',
	               	  '20','21','22','23','24','25','26','27','28','29','30','31','32','33','34','35','36','37','38','39',
	               	  '40','41','42','43','44','45','46','47','48','49','50','51','52','53','54','55','56','57','58','59'];
	for( var i  = 0; i< 60; i++)
	{
		var mtstr = minuteList[i];
		var mtlg  = MTime.language["minute"][0];
		mt.options[mt.length] = new Option( mtstr + mtlg, i );
	}
};

MTime.prototype.bindSecond = function()
{
	var sc 		= this.form.secondSelect;
	sc.length	= 0 ;
	
	var secondList 	=['00','01','02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','19',
	               	  '20','21','22','23','24','25','26','27','28','29','30','31','32','33','34','35','36','37','38','39',
	               	  '40','41','42','43','44','45','46','47','48','49','50','51','52','53','54','55','56','57','58','59'];
	for( var i  = 0; i< 60; i++)
	{
		var scstr = secondList[i];
		var sclg  = MTime.language["second"][0];
		sc.options[sc.length] = new Option( scstr + sclg, i );
	}
};

MTime.prototype.bindTime = function()
{
	this.form.hourSelect.options[this.hour].selected	 = true;
	this.form.minuteSelect.options[this.minute].selected = true;
	this.form.secondSelect.options[this.second].selected = true;
};

MTime.prototype.parseTime = function(timeStr)
{
	var pattern = new RegExp(":","g");
	var vtime =  String(timeStr).replace(pattern, "");
	vtime =  String(vtime).replace(/^0*/, "");
	
	var itime = parseInt(vtime);
	var arrTime = [0,0,0];
	arrTime[0] = parseInt(itime / 10000);
	arrTime[1] = parseInt((itime % 10000) / 100);
	arrTime[2] = itime % 100;
	
	return arrTime;
};


MTime.prototype.show = function(pntItem)
{

	//控制可见性
	if(this.panel.style.visibility == "visible")
	{
		this.panel.style.visibility = "hidden";
		return ;
	}
	
	this.parentControl = pntItem;
	
	if(pntItem.value.length > 0 ){
		var arrTime = this.parseTime(pntItem.value);
		this.hour 	= arrTime[0];
		this.minute = arrTime[1];
		this.second = arrTime[2];
	}

	//绘制但不显示
	this.draw();
	
	//绑定时间
	this.bindHour();
	this.bindMinute();
	this.bindSecond();
	
	//设置时间
	this.bindTime();
	
	var xy = this.getAbsPoint(pntItem);	
	this.panel.style.left = xy.x + "px";
	this.panel.style.top  = (xy.y + pntItem.offsetHeight + 4) + "px";
	this.panel.style.visibility = "visible";

};

MTime.prototype.hide = function()
{
	if(this.panel.style.visibility == "visible" && arguments[0] != this.parentControl)
	{
		this.panel.style.visibility = "hidden";
	}
};


MTime.prototype.getAbsPoint = function(e){
	var x = e.offsetLeft;
	var y = e.offsetTop;
	while(e = e.offsetParent){
		x += e.offsetLeft;
		y += e.offsetTop;
	}
	
	return {"x":x, "y":y};
};


document.writeln('<div id="__timePanel" style="position:absolute;visibility:hidden;z-index:9999;background-color:#FFFFFF;border:1px solid #666666;width:180px;height:24px;">');
document.writeln('<iframe name="__timeIframe" id="__timeIframe" width="100%" height="100%" scrolling="no" frameborder="0" style="margin:0px;"><\/iframe>');
document.writeln('<br/>');

var __ci = window.frames['__timeIframe'];
__ci.document.writeln('<!DOCTYPE html PUBLIC "-\/\/W3C\/\/DTD XHTML 1.0 Transitional\/\/EN" "http:\/\/www.w3.org\/TR\/xhtml1\/DTD\/xhtml1-transitional.dtd">');
__ci.document.writeln('<html xmlns="http:\/\/www.w3.org\/1999\/xhtml">');
__ci.document.writeln('<head>');
__ci.document.writeln('<meta http-equiv="Content-Type" content="text\/html; charset=utf-8" \/>');
__ci.document.writeln('<title>Web Calendar<\/title>');
__ci.document.writeln('<style type="text\/css">');
__ci.document.writeln('<!--');
__ci.document.writeln('body {font-size:12px;margin-top:0px;margin-left:0px;text-align:center;border:0px;}');
__ci.document.writeln('form {margin:0px;}');
__ci.document.writeln('-->');		
__ci.document.writeln('<\/style>');
__ci.document.writeln('<\/head>');
__ci.document.writeln('<body><\/body><\/html>');

document.writeln('</div>');

var mtime = new MTime();
document.onclick=
	function(e) 
	{
		e = window.event || e;
		var srcElement = e.srcElement || e.target;
		mtime.hide(srcElement);
	}