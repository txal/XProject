#include "Common/WordFilter/WordFilter.h"
#include "Include/Script/Script.hpp"
#include <string>

#define TREE_WIDTH 256
#define WORDLENMAX 256

struct trie_node_st {
	short count;
	struct trie_node_st *next[TREE_WIDTH];
};

static struct trie_node_st root={0, {NULL}};
static int insert(const unsigned char *word) {
	int i;
	struct trie_node_st *curr, *newnode;

	if ('\0' == word[0]) {
		return 0;
	}
	curr = &root;
	for (i=0; ; ++i) {
		if (NULL == curr->next[ word[i] ]) {
			newnode = (struct trie_node_st*)malloc(sizeof(struct trie_node_st));
			memset(newnode, 0, sizeof(struct trie_node_st));
			curr->next[ word[i] ] = newnode;
		}
		if ('\0' == word[i]) {
			break;
		}
		curr = curr->next[ word[i] ];
	}
	curr->count++;
	return 0;
}

bool search(const unsigned char *cont) {
	struct trie_node_st *node = &root;
	unsigned i = 0, p = 0, len = (unsigned)strlen((char*)cont);

	while (i < len) {
		node = node->next[ cont[i] ];
		if (NULL == node) {
			node = &root;
			i -= p;
			p = 0;
		} else if (node->count) {
			return true;
		} else {
			p++;
		}
		i++;
	}
	return false;
}

char *replace(unsigned char *cont, unsigned char c) {
	struct trie_node_st *node = &root;
	unsigned i = 0, p = 0, len = (unsigned)strlen((char*)cont);
	unsigned ids[WORDLENMAX] = {0};

	while (i < len) {
		node = node->next[ cont[i] ];
		if (NULL == node) {
			node = &root;
			i -= p;
			p = 0;
		} else if (node->count) {
			ids[p++] = i;
			for (unsigned k=0; k<p; k++) {
				*(cont+ids[k]) = c;
			}
			i = i - p + 1;
			p = 0;
			node = &root;
		} else {
			ids[p++] = i;
		}
		i++;
	}
	return (char*)cont;
}

bool init_filter(const char *path) {
	//FILE *fp = fopen(path, "r");
	//if (NULL == fp) {
	//	perror(path);
	//	return false;
	//}
	//char *line = NULL;
	//int len = 0;
	//int read = 0;
	//while ((read=getline(&line, &len, fp)) != -1) {
	//	if (read>=2 && line[read-2]=='\r')
	//		line[read-2] = '\0';
	//	else if (read>0 && line[read-1]=='\n')
	//		line[read-1] = '\0';
	//	if ('\0' == line[0]) continue;
	//	insert((unsigned char*)line);
	//}
	//if (line) free(line);
	//fclose(fp);
	return true;
}

/*
static void printword(const char *str, int n) {
	printf("%s\t%d\n", str, n);
}

static int do_travel(struct trie_node_st *rootp) {
	static char worddump[WORDLENMAX+1];
	static int pos=0;
	int i;

	if (NULL == rootp) {
		return 0;
	}
	if (rootp->count) {
		worddump[pos]='\0';
		printword(worddump, rootp->count);
	}
	for (i=0;i<TREE_WIDTH;++i) {
		worddump[pos++]=i;
		do_travel(rootp->next[i]);
		pos--;
	}
	return 0;
}

int main(void) {
	init_filter("./badword.txt");
	char *line = NULL;
	unsigned len = 0, read = 0;
	while (true) {
		printf("input:");
		read = getline(&line, &len, stdin);
		if (read == -1) break;
		if (read>=2 && line[read-2]=='\r')
			line[read-2] = '\0';
		else if (read>0 && line[read-1]=='\n')
			line[read-1] = '\0';
		if (line[0] == '\0') continue;
		printf("search %s: %d\n", line, search((unsigned char*)line));
		printf("replace %s: %s\n", line, replace((unsigned char*)line, '*'));
	}
	if (line) free(line);
	exit(0);
}
*/

///////////导出到LUA//////////
static int AddWord(lua_State* pState)
{
	size_t nLen = 0;
	const char* pWord = luaL_checklstring(pState, -1, (size_t*)&nLen);
	if ((int)nLen >= WORDLENMAX)
	{
		return LuaWrapper::luaM_error(pState, "文字过长");
	}
	insert((unsigned char*)pWord);
	return 0;
}

static int HasWord(lua_State* pState)
{
	const char* pText = luaL_checkstring(pState, -1);
	bool bRes = search((unsigned char*)pText);
	lua_pushboolean(pState, bRes);
	return 1;
}

static int ReplaceWord(lua_State* pState)
{
	const char* pText = luaL_checkstring(pState, -2);
	const char* pReplace = luaL_checkstring(pState, -1);
	const char* pRes = replace((unsigned char*)pText, pReplace[0]);
	lua_pushstring(pState, pRes);
	return 1;
}

void RegWordFilter(const char* psTable)
{
	luaL_Reg _timermgr_func[] =
	{
		{ "AddWord", AddWord },
		{ "HasWord", HasWord },
		{ "ReplaceWord", ReplaceWord },
		{ NULL, NULL },
	};
	LuaWrapper::Instance()->RegFnList(_timermgr_func, psTable);
}