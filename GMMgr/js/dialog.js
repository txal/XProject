/**
* @author : Kinroc (http://www.kinroc.com/)
* @author : Jessica (http://www.skiyo.cn)
* @name JS遮罩层例子
* @version 1.0
*/
function Dialog(obj,maskID,opacity,titleID,dialogID,cssName,width,height,isMove,isSize,ContentID){
	this.obj = obj?obj:null;//对象名
	this.maskID = maskID?maskID:null;//遮罩ID
	this.opacity = opacity?opacity:50;//遮罩层透明度(默认为50,火狐下为该值除以100,即0.5)
	this.titleID = titleID?titleID:null;//窗口标题ID
	this.dialogID = dialogID?dialogID:null;//对话框ID
	this.cssName = cssName?cssName:null;//css类名
	this.width = width?width:null;//窗口宽度
	this.height = height?height:null;//窗口高度
	this.isMove = isMove?isMove:false;//是否移动(true/false)
	this.isSize = isSize?isSize:false;//是否可以调整大小(true/false)
	this.ContentID = ContentID?ContentID:null;//内容ID
	this.x0 = 0;
	this.y0 = 0;
	this.x1 = 0;
	this.y1 = 0;
	this.moveable = false;
}

//设置对象名
Dialog.prototype.SetObj = function(obj){
	this.obj = obj?obj:null;
};

//设置遮罩层透明度(默认为50,火狐下为该值除以100,即0.5)
Dialog.prototype.SetOpacity = function(opacity){
	this.opacity = opacity?opacity:null;
};

//设置窗口标题ID
Dialog.prototype.SetTitleID = function(titleID){
	this.titleID = titleID?titleID:null;
};

//设置遮罩ID
Dialog.prototype.SetMaskID = function(maskID){
	this.maskID = maskID?maskID:null;
};

//设置对话框ID
Dialog.prototype.SetDialogID = function(dialogID){
	this.dialogID = dialogID?dialogID:null;
};

//设置css类名
Dialog.prototype.SetCssName = function(cssName){
	this.cssName = cssName?cssName:null;
};

//设置窗口宽度
Dialog.prototype.SetWidth = function(width){
	this.width = width?width:null;
};

//设置窗口高度
Dialog.prototype.SetHeight = function(height){
	this.height = height?height:null;
};

//设置移动区域(空则代表不能移动)
Dialog.prototype.SetMoveID = function(MoveID){
	this.MoveID = MoveID?MoveID:null;
	if(this.isMove){
		if(this.MoveID){
			var move_id = this.MoveID;
			var parent = this.obj;
			this.$(move_id).onmousedown = function(event){
				eval(parent).startMove(event);
			};

			this.$(move_id).onmouseup = function(){
				eval(parent).stopMove();
			};

			this.$(move_id).onmousemove = function(event){
				eval(parent).Moveing(event);
			};
		}
	}
};

//设置是否可以移动(true/false)
Dialog.prototype.SetIsMove = function(isMove){
	this.isMove = isMove?isMove:false;
};

//设置是否可以调整大小(true/false)
Dialog.prototype.SetIsSize = function(isSize){
	this.isSize = isSize?isSize:false;
};

//设置内容ID
Dialog.prototype.SetContentID = function(ContentID){
	this.ContentID = ContentID?ContentID:null;
};

//设置遮罩层颜色(默认为#f0f0f0)
Dialog.prototype.SetMaskColor = function(MaskColor){
	this.MaskColor = MaskColor?MaskColor:null;
};

//设置对话框里的内容
Dialog.prototype.SetContent = function(content){
	if(content){
		if(typeof content =="object"){
			this.content = content.innerHTML;
		}else{
			this.content = content;
		}
	}
};

//设置对话框里的标题
Dialog.prototype.SetTitle = function(title){
	this.title = title?title:null;
};

//设置关闭按钮ID
Dialog.prototype.SetCloseID = function(CloseID){
	this.CloseID = CloseID?CloseID:null;
	var parent = this.obj;
	if(this.CloseID){
		this.$(this.CloseID).onclick = function(){
			eval(parent).CloseMask();
		};
	}
};

//设置关闭回调函数
Dialog.prototype.SetCloseFunction = function(functionName){
	this.closeFunction = functionName||null;
};

//设置某个ID的事件
Dialog.prototype.SetEventByID = function(ID,Type,functionName){
	if(ID){
		if(this.$(ID)){
			var ____EID = this.$(ID);
			if(eval("____EID."+Type+"=function(){};")){
				eval("____EID."+Type+"=function(){"+functionName+";};");
			}
			//				switch(Type){
			//					case 'onclick':
			//						____EID.onclick = function(){eval(functionName);};
			//						break;
			//					case 'ondblclick':
			//						____EID.ondblclick = function(){eval(functionName);};
			//						break;
			//					default:
			//						____EID.onclick = function(){eval(functionName);};
			//						break;
			//				}
		}
	}
};


//根据div的ID生成一个透明的div遮罩层,如果divID为空则创建DIV
Dialog.prototype.____CreateMaskDiv = function(){
	if(this.maskID){
		var div_Mask = null;
		if(this.$(this.maskID)){
			div_Mask = this.$(this.maskID);
			div_Mask.style.zIndex = "999";
			div_Mask.style.position = "absolute";
			div_Mask.style.backgroundColor = this.MaskColor?this.MaskColor:"#000000";
			div_Mask.style.width = this.____GetHtmlBodySize()[0] + "px";
			div_Mask.style.height = this.____GetHtmlBodySize()[1] + "px";
			div_Mask.style.top = "0px";
			div_Mask.style.left = "0px";
			div_Mask.style.filter = "alpha(opacity="+this.opacity+")";
			div_Mask.style.opacity = this.opacity/100;
			div_Mask.style.display = "";
		}else{
			div_Mask = document.createElement("DIV");
			div_Mask.id = this.maskID;
			div_Mask.style.zIndex = "999";
			div_Mask.style.position = "absolute";
			div_Mask.style.backgroundColor = this.MaskColor?this.MaskColor:"#000000";
			div_Mask.style.width = this.____GetHtmlBodySize()[0] + "px";
			div_Mask.style.height = this.____GetHtmlBodySize()[1] + "px";
			div_Mask.style.top = "0px";
			div_Mask.style.left = "0px";
			div_Mask.style.filter = "alpha(opacity="+this.opacity+")";
			div_Mask.style.opacity = this.opacity/100;
			document.body.insertBefore(div_Mask, null);
		}
	}
};

//根据div的ID生成对话框
Dialog.prototype.CreateDialogDiv = function(){
	var dialog_id = this.dialogID;

	if(dialog_id){

		if(this.$(dialog_id)){

			this.____CreateMaskDiv();
			var divDialog = this.$(dialog_id);

			if(this.cssName){
				divDialog.className = this.cssName
			}

			var Content_id = this.ContentID;
			if(Content_id){
				if(this.$(Content_id)){
					var DialogContent = this.$(Content_id);
					if(this.content){
						DialogContent.innerHTML = this.content;
					}
					DialogContent.style.display = "";
				}
			}

			var Title = this.$(this.titleID);
			if(Title){
				if(typeof Title =="object"){
					this.title = Title.innerHTML;
				}else{
					this.title = Title;
				}
				Title.style.display = "";
			}

			if(this.width){
				divDialog.style.width = this.width;
			}
			if(this.height){
				divDialog.style.height = this.height;
			}

			divDialog.style.zIndex = "9999";
			divDialog.style.position = "absolute";
			divDialog.style.display = "";

			var ____scrollPos = 0;
			if(typeof window.pageYOffset != 'undefined') {
				____scrollPos = window.pageYOffset;
			}else if(typeof document.compatMode != 'undefined' && document.compatMode != 'BackCompat'){
				____scrollPos = document.documentElement.scrollTop;
			}else if(typeof document.body != 'undefined'){
				____scrollPos = document.body.scrollTop;
			}
			divDialog.style.top = ((document.documentElement.clientHeight-divDialog.offsetHeight)/2+____scrollPos)+"px";
			divDialog.style.left = (document.body.offsetWidth-divDialog.offsetWidth)/2+"px";
		}
	}
};

//开始移动窗口
Dialog.prototype.startMove = function(e){
	if(this.isMove){
		e = e||event;
		if(e.button==1||e.button==0){
			var move_id = this.$(this.MoveID);
			var win = this.$(this.dialogID);
			if(move_id.setCapture){
				move_id.setCapture();
			}
			var parent = this.obj;
			this.addListener(document.body,"mousemove",this.Moveing,false);
			this.addListener(document.body,"mouseup",this.stopMove,false);
			this.x0 = e.pageX||e.clientX;
			this.y0 = e.pageY||e.clientY;
			this.x1 = win.offsetLeft;
			this.y1 = win.offsetTop;

			this.moveable = true;
		}
	}
};

//停止移动窗口
Dialog.prototype.stopMove = function(){
	if(this.moveable){
		var move_id = this.$(this.MoveID);
		var win = this.$(this.dialogID);
		if(move_id.releaseCapture){
			move_id.releaseCapture();
		}
		var parent = this.obj;
		this.removeListener(document.body,"mousemove",this.Moveing,false);
		this.removeListener(document.body,"mouseup",this.stopMove,false);

		this.moveable = false;

	}
};

//移动窗口
Dialog.prototype.Moveing = function(e){
	if(this.moveable){
		e = e||event;
		var win = this.$(this.dialogID);
		var ____now_x = e.pageX||e.clientX;
		var ____now_y = e.pageY||e.clientY;
		win.style.left = (this.x1 + ____now_x - this.x0)+"px";
		win.style.top = (this.y1 + ____now_y - this.y0)+"px";
	}
};

//关闭div并销毁对象
Dialog.prototype.CloseMask = function(){
	if(this.$(this.maskID)){
		this.$(this.maskID).style.display = "none";
	}
	if(this.$(this.dialogID)){
		this.$(this.dialogID).style.display = "none";
	}
	if(this.obj){
		var closeObj = eval(this.obj);
		closeObj = null;
	}
	if(this.closeFunction){
		eval(this.closeFunction);
	}
};

//添加监听器
Dialog.prototype.addListener = function(element,name,functionName,useCapture){
	useCapture = useCapture||false;
	if(name=='keypress'&&(navigator.appVersion.match(/Konqueror|Safari|KHTML/)||element.attachEvent))name='keydown';
	if(element.addEventListener){
		element.addEventListener(name,functionName,useCapture);
	}else{
		if(element.attachEvent){
			element.attachEvent('on'+name,functionName);
		}
	}
};

//移除监听器
Dialog.prototype.removeListener = function(element,name,functionName,useCapture){
	useCapture = useCapture||false;
	if(name=='keypress'&&(navigator.appVersion.match(/Konqueror|Safari|KHTML/)||element.detachEvent))name='keydown';
	if(element.removeEventListener){
		element.removeEventListener(name,functionName,useCapture);
	}else{
		if(element.detachEvent){
			element.detachEvent('on'+name,functionName);
		}
	}
};

//取得网页的宽高
Dialog.prototype.____GetHtmlBodySize = function(){
	var myWidth = 0, myHeight = 0;
	if( typeof( window.innerWidth ) == 'number' ) {
		//Non-IE
		myWidth = window.innerWidth;
		myHeight = window.innerHeight;
	} else if( document.documentElement && ( document.documentElement.clientWidth || document.documentElement.clientHeight ) ) {
		//IE 6+ in 'standards compliant mode'
		myWidth = document.documentElement.clientWidth;
		myHeight = document.documentElement.clientHeight;
	} else if( document.body && ( document.body.clientWidth || document.body.clientHeight ) ) {
		//IE 4 compatible
		myWidth = document.body.clientWidth;
		myHeight = document.body.clientHeight;
	}
	return [
	myWidth,
	myHeight
	];

};

//getElementById
Dialog.prototype.$ = function() {
	var elements = new Array();
	for (var i = 0; i < arguments.length; i++) {
		var element = arguments[i];
		if (typeof element == 'string')
		element = document.getElementById(element);
		if (arguments.length == 1)
		return element;
		elements.push(element);
	}
	return elements;
};