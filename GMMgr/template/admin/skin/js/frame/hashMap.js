function mashMap()
{
	var size = 0 ;
	var entry = new Object();
	
	this.put = function(key, value)
	{
		if(!this.containsKey(key))
		{
			size ++;
		}
		entry[key] = value;
	}
}