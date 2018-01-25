//非法字过滤器
#ifndef __FILTER_H__
#define __FILTER_H__

	bool init_filter(const char *path);
	bool search(const unsigned char *cont);
	char *replace(unsigned char *cont, unsigned char c);

	//注册文字过滤器到LUA
	void RegWordFilter(const char* psTable);

#endif
