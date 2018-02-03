function mashMap()
{
	var size = 0 ;
	var entry = new Object();
	
	this.put = function(key, value)
	{
		if(!this.has(key))
		{
			size ++;
		}
		entry[key] = value;
	}

	this.pop = function(key)
	{
		if(this.has(key) && (delete entry[key]))
		{
			size --;
		}
	}

	this.has = function(key)
	{
		return (key in entry);
	}

	this.size = function()
	{
		return size;
	}

	this.parseStr = function()
	{
		var str = "";
		var mod = "";
		for(var key in entry)
		{
			var item = entry[key];
			str = str + mod + (item.name + "=" + item.amount + "个") ;
			mod = ",";
		}

		return str;
	}

	this.parseArrayValue = function()
	{
		var str = "";
		var mod = "";
		for(var key in entry)
		{
			var item = entry[key];
			str = str + mod + (item.id + "=" + item.amount) ;
			mod = ",";
		}

		return str;
	}
	
	
	//返回索引组成的字符串,用逗号分隔
	//如:    key1,key2,key3,...
	this.getKeysWithComma = function()
	{
		var str = "";
		var mod = "";
		for(var key in entry)
		{
			str = str + mod + key;
			mod = ",";
		}
		
		return str;
	}
	
	//返回值组成的字符串,用逗号分隔
	//如:    value1,value2,value3,...
	this.getValuesWithChacter = function(ch)
	{
		var str = "";
		var mod = "";
		for(var key in entry)
		{
			str = str + mod + entry[key];
			mod = ch;
		}
		
		return str;
	}	
}