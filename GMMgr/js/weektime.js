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
function WeekTime(hiddenItem)
{
	this.value = 2;	
	this.panel = this.getElementById("__timePanel");
	this.iframe = window.frames["__timeIframe"];
	this.parentControl = null;
	this.hiddenItem = hiddenItem;	

	this.date 	= new Date();
	this.week 	= this.date.getDay();
	this.hour 	= this.date.getHours();
	this.minute = this.date.getMinutes();
	this.second = this.date.getSeconds();
	
};

WeekTime.language = {
	"weekb"	 : ["\u661f\u671f"],
	"week"	 : ["\u65e5","\u4e00","\u4e8c","\u4e09","\u56db","\u4e94","\u516d"],
	
	"hour"	 : ["\u65F6"],
	"minute" : ["\u5206"],
	"second" : ["\u79D2"],
};

WeekTime.prototype.getElementById = function(id)
{
	return document.getElementById(id);
};

WeekTime.prototype.format = function(string)
{
	var args = arguments;
	var pattern = new RegExp("%[0-9]*[ds]","g");
	var counter = 1;
	return String(string).replace(pattern, 
		function(match, index)
		{
			counter = counter + 1 ;
			var sv = args[counter -1 ];
			var iv = parseInt(sv);
			if(iv != false && iv < 10)
			{
				return "0" + iv;
			}else{
				return sv;
			}
		}
	);
};

WeekTime.prototype.iWeekTimeValue = function(week, hour, minute, second)
{
	//week 从星期天  0 开始  
	var total = 0 ;
	total = total + week * 24* 3600;	
	total = total + hour * 3600;		
	total = total + minute * 60;		
	total = total + second;				

	return total;
};

WeekTime.prototype.update = function(e)
{
	this.week  	= parseInt(e.form.weekSelect.options[e.form.weekSelect.selectedIndex].value);
	this.hour  	= parseInt(e.form.hourSelect.options[e.form.hourSelect.selectedIndex].value);
	this.minute	= parseInt(e.form.minuteSelect.options[e.form.minuteSelect.selectedIndex].value);
	this.second	= parseInt(e.form.secondSelect.options[e.form.secondSelect.selectedIndex].value);
	
	var weekStr = WeekTime.language['weekb'][0] + WeekTime.language['week'][this.week];
	var value = this.format("%s %2d:%2d:%2d", weekStr , this.hour, this.minute, this.second);
	this.parentControl.value = value;
	
	this.hiddenItem.value = this.iWeekTimeValue(this.week, this.hour, this.minute, this.second);

};

WeekTime.prototype.draw = function()
{
	weektime = this;

	var _cs = [];
	_cs[_cs.length] = '<form id="__timeForm" name="__timeForm" method="post">';
	_cs[_cs.length] = '<table width="100%" border="0" cellpadding="0" cellspacing="1" align="left">';
	_cs[_cs.length] = '<tr>';
	_cs[_cs.length] = '<td align="left" style="border-right:1px solid"><select id="weekSelect" name="weekSelect" style="border:none;"><\/select><\/div><\/td>';	
	_cs[_cs.length] = '<td align="left" style="border-right:1px solid"><select id="hourSelect" name="hourSelect" style="border:none;"><\/select><\/div><\/td>';
	_cs[_cs.length] = '<td align="left" style="border-right:1px solid"><div><select id="minuteSelect" name="minuteSelect" style="border:none;"><\/select><\/div><\/td>';
	_cs[_cs.length] = '<td align="left"><div><select id="secondSelect" name="secondSelect" style="border:none;"><\/select><\/div><\/td>';
	_cs[_cs.length] = '<\/tr>';
	_cs[_cs.length] = '<\/table>';
	
	//存贮全局变量
	this.iframe.document.body.innerHTML = _cs.join("");
	this.form = this.iframe.document.forms["__timeForm"];
	
	//绑定事件
	this.form.weekSelect.onchange = function () 
	{
		weektime.update(this);
	};	
	
	this.form.hourSelect.onchange = function () 
	{
		weektime.update(this);
	};
	
	this.form.minuteSelect.onchange = function () 
	{
		weektime.update(this);
	};
	
	this.form.secondSelect.onchange = function () 
	{
		weektime.update(this);
	};

};

WeekTime.prototype.bindWeek = function()
{
	var wk 		= this.form.weekSelect;
	wk.length	= 0 ;
	
	var weekList=['日','一','二','三','四','五','六'];	
	for( var i  = 0; i< 7; i++)
	{
		var wlgb = WeekTime.language["weekb"][0];
		var wlg  = WeekTime.language["week"][i];
		wk.options[wk.length] = new Option(wlgb + wlg, i );
	}
};

WeekTime.prototype.bindHour = function()
{
	var hr 		= this.form.hourSelect;
	hr.length	= 0 ;
	
	var hourList=['00','01','02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','19','20','21','22','23'];	
	for( var i  = 0; i< 24; i++)
	{
		var hstr = hourList[i];
		var hlg  = WeekTime.language["hour"][0];
		hr.options[hr.length] = new Option( hstr + hlg, i );
	}
};

WeekTime.prototype.bindMinute = function()
{
	var mt 		= this.form.minuteSelect;
	mt.length	= 0 ;
	
	var minuteList 	=['00','01','02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','19',
	               	  '20','21','22','23','24','25','26','27','28','29','30','31','32','33','34','35','36','37','38','39',
	               	  '40','41','42','43','44','45','46','47','48','49','50','51','52','53','54','55','56','57','58','59'];
	for( var i  = 0; i< 60; i++)
	{
		var mtstr = minuteList[i];
		var mtlg  = WeekTime.language["minute"][0];
		mt.options[mt.length] = new Option( mtstr + mtlg, i );
	}
};

WeekTime.prototype.bindSecond = function()
{
	var sc 		= this.form.secondSelect;
	sc.length	= 0 ;
	
	var secondList 	=['00','01','02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','19',
	               	  '20','21','22','23','24','25','26','27','28','29','30','31','32','33','34','35','36','37','38','39',
	               	  '40','41','42','43','44','45','46','47','48','49','50','51','52','53','54','55','56','57','58','59'];
	for( var i  = 0; i< 60; i++)
	{
		var scstr = secondList[i];
		var sclg  = WeekTime.language["second"][0];
		sc.options[sc.length] = new Option( scstr + sclg, i );
	}
};

WeekTime.prototype.bindTime = function()
{
	this.form.weekSelect.options[this.week].selected	 = true;
	this.form.hourSelect.options[this.hour].selected	 = true;
	this.form.minuteSelect.options[this.minute].selected = true;
	this.form.secondSelect.options[this.second].selected = true;
};

WeekTime.prototype.parseTime = function(timeStr)
{
	//var pattern = new RegExp("[:-]*","g");
	//var vtime =  String(timeStr).replace(pattern, "");
	//vtime =  String(vtime).replace(/^0*/, "");
	
	//var itime = parseInt(vtime);
	var itime 	= parseInt(timeStr);
	var arrTime = [0,0,0,0];
	
	arrTime[0] 	= parseInt(itime / (24*3600));	itime = itime % (24*3600);
	arrTime[1]	= parseInt(itime / 3600 ) ;		itime = itime % 3600;
	arrTime[2]	= parseInt(itime / 60 );		itime = itime % 60 ;
	arrTime[3]	= itime;
	
	return arrTime;
};


WeekTime.prototype.show = function(pntItem)
{

	//控制可见性
	if(this.panel.style.visibility == "visible")
	{
		this.panel.style.visibility = "hidden";
		return ;
	}
	
	this.parentControl = pntItem;
	
	if(this.hiddenItem.value.length > 0 ){

		var arrTime = this.parseTime(this.hiddenItem.value);
		this.week 	= arrTime[0]
		this.hour 	= arrTime[1];
		this.minute = arrTime[2];
		this.second = arrTime[3];
	}

	//绘制但不显示
	this.draw();

	//绑定时间
	this.bindWeek()
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

WeekTime.prototype.hide = function()
{
	if(this.panel.style.visibility == "visible" && arguments[0] != this.parentControl)
	{
		this.panel.style.visibility = "hidden";
	}
};


WeekTime.prototype.getAbsPoint = function(e){
	var x = e.offsetLeft;
	var y = e.offsetTop;
	while(e = e.offsetParent){
		x += e.offsetLeft;
		y += e.offsetTop;
	}
	
	return {"x":x, "y":y};
};


document.writeln('<div id="__timePanel" style="position:absolute;visibility:hidden;z-index:9999;background-color:#FFFFFF;border:1px solid #666666;width:240px;height:24px;">');
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

var weektime = new WeekTime();
document.onclick=
	function(e) 
	{
		e = window.event || e;
		var srcElement = e.srcElement || e.target;
		weektime.hide(srcElement);
	}