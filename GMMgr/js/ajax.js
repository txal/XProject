/*+-----------------------+
  | @copyright: gz.com    |
  | @author: liexusong    |
  | @date: 2010           |
  +-----------------------+*/
/*
if (typeof XMLHttpRequest == 'undefined') {
	XMLHttpRequest = function() {
		return new ActiveXObject(
			navigator.userAgent.indexOf('MSIE 5') >= 0 ? 
			"Microsoft.XMLHTTP" : "Msxml2.XMLHTTP"
		);
	};
}

function ajax (options) {
	options = {
		type: options.type || "POST",
		url: options.url || "",
		
		timeout: options.timeout || 5000,
		
		onComplete: options.onComplete || function() {},
		onError: options.onError || function() {},
		onSuccess: options.onSuccess || function() {},
		onLoading: options.onLoading || function() {},
		data: options.data || {}
	};
	
	var xml = new XMLHttpRequest();
	
	xml.open(options.type, options.url, true);
	
	var timeoutLength = options.timeout;
	var requestDone = false;
	
	setTimeout(function() {
		requestDone = true;
	}, timeoutLength);
	
	xml.onreadystatechange = function() {
		if (xml.readyState == 4 && !requestDone) {
			if (xml.status == 200) {
				options.onSuccess(httpData(xml, options.type));
			} else {
				options.onError();
			}
			
			options.onComplete();
			xml = null;
		} else if(xml.readyState != 4 && !requestDone) {
			if (options.onLoading) {
				options.onLoading();
			}
		}
	};

	xml.setRequestHeader("If-Modified-Since","0");
	xml.setRequestHeader('Content-Type', 'text/html; charset=gbk');
	xml.send((options.type.toLowerCase() == 'post' ? serialize(options.data) : null));
	
	function httpSuccess(r) {
		try {
			return !r.status && location.protocol == 'file:' || (r.status >= 200 && r.status < 300) || r.status == 304 || navigator.userAgent.indexOf('Safari') >= 0 && typeof r.status == 'undefined';
		} catch(e) {}
		return false;
	}
	
	function httpData(r, type) {
		var ct = r.getResponseHeader('content-type');
		var data = !type && ct && ct.indexOf('xml') >= 0;
		
		data = type == 'xml' || data ? r.responseXML : r.responseText;
		
		if (type == 'script') {
			eval.call(window, data);
		}
		return data;
	}
}

function serialize(a) {
	var s = [];
	if (a.constructor == Array) {
		for (var i = 0; i < a.length; i++)
			s.push(a[i].name + "=" + encodeURIComponent(a[i].value));
	} else {
		for (var j in a) {
			s.push(j + "=" + encodeURIComponent(a[j]));
		}
	}
	return s.join('&');
}
*/
function ajax(url, w, resulthandle) {
	var request = false;
	if(window.XMLHttpRequest) {
		request = new XMLHttpRequest();
		if(request.overrideMimeType) {
			request.overrideMimeType('text/xml');
		}
	} else if(window.ActiveXObject) {
		var versions = ['Microsoft.XMLHTTP', 'MSXML.XMLHTTP', 'Microsoft.XMLHTTP', 'Msxml2.XMLHTTP.7.0', 'Msxml2.XMLHTTP.6.0', 'Msxml2.XMLHTTP.5.0', 'Msxml2.XMLHTTP.4.0', 'MSXML2.XMLHTTP.3.0', 'MSXML2.XMLHTTP'];
		for(var i=0; i<versions.length; i++) {
			try {
				request = new ActiveXObject(versions[i]);
			} catch(e) {}
		}
	}
	if(w=='get') {
		request.open('GET', url, true);
		request.onreadystatechange = function () {
			if (request.readyState == 4){
				if (request.status == 200) {
					var texts = request.responseText;
					resulthandle(texts);
				}
			}
		};
		request.send(null);
	} else {
		request.open('POST', url);
		request.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
		request.onreadystatechange = function () {
			if (request.readyState == 4){
				if (request.status == 200) {
					var texts = request.responseText;
					resulthandle(texts);
				}
			}
		};
		request.send(w);
	}
}