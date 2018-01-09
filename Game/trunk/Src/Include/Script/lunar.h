#ifndef __LUNAR_H__
#define __LUNAR_H__

#include "LuaInc/lua.hpp"

static inline void
DumpTable(lua_State *L, int index = -1)
{
	lua_pushvalue(L, index);
	lua_getglobal(L, "table");
	lua_getfield(L, -1, "Print");
	if (lua_isnil(L, -1))
	{
		fprintf(stderr, "'table.Print' not defined\n");
		return;
	}
	lua_pushvalue(L, -3);
	lua_pcall(L, 1, 0, 0);
	lua_pop(L, 2);
}


typedef int(*PreDelete)(lua_State *L);

template <typename T> class Lunar// lookup[key] = userdata
{
public:
	typedef struct { T *pT; } userdataType;
	typedef int (T::*mfp)(lua_State *L);
	typedef struct { const char *name; mfp mfunc; } RegType;

	static void Register(lua_State *L, bool del = false, PreDelete pre = NULL)
	{
		lua_newtable(L);
		int methods = lua_gettop(L);

		// 创建一个新表(将用作metatable)
		// 将新表放到栈顶并建立表和registry中类型名的联系.
		luaL_newmetatable(L, T::className);
		int metatable = lua_gettop(L);

		// store method table in globals so that
		// scripts can add functions written in Lua.
		lua_pushglobaltable(L);
		int gindex = lua_gettop(L);
		lua_pushvalue(L, methods);
		set(L, gindex, T::className);
		lua_pop(L, 1);

		// hide metatable from Lua getmetatable()
		lua_pushvalue(L, methods);
		set(L, metatable, "__metatable");

		lua_pushvalue(L, methods);
		set(L, metatable, "__index");

		lua_pushcfunction(L, tostring_T);
		set(L, metatable, "__tostring");

		if (pre)
		{
			del = true;
			lua_pushcfunction(L, pre);
		}
		else
		{
			lua_pushcfunction(L, gc_T);
		}
		set(L, metatable, "__gc");

		// mt for method table
		lua_newtable(L);
		if (del)
			lua_pushcfunction(L, d_new_T);
		else
			lua_pushcfunction(L, new_T);

		// dup new_T function
		lua_pushvalue(L, -1);
		// add new_T to method table
		set(L, methods, "new");

		// mt.__call = new_T
		set(L, -3, "__call");
		// 把一个 table 弹出堆栈,并将其设为给定索引处的值的 metatable.
		lua_setmetatable(L, methods);

		// fill method table with methods from class T
		for (RegType *l = T::methods; l->name; l++)
		{
			lua_pushstring(L, l->name);
			// 把一个 light userdata 压栈. userdata 在 Lua 中表示一个 C 值. light userdata 表示一个指针.
			// 它是一个像数字一样的值:你不需要专门创建它,它也没有独立的 metatable,
			// 而且也不会被收集(因为从来不需要创建). 只要表示的 C 地址相同, 两个 light userdata 就相等.
			lua_pushlightuserdata(L, (void*)l);
			// 把一个新的 C closure 压入堆栈.
			// 当创建了一个 C 函数后，你可以给它关联一些值，这样就是在创建一个 C closure.
			// 接下来无论函数何时被调用,这些值都可以被这个函数访问到.
			// 为了将一些值关联到一个 C 函数上,首先这些值需要先被压入堆栈(如果有多个值,第一个先压).
			// 接下来调用 lua_pushcclosure 来创建出 closure 并把这个 C 函数压到堆栈上.
			// 参数 n 告之函数有多少个值需要关联到函数上.
			// lua_pushcclosure 也会把这些值从栈上弹出.
			if (!del && strcmp(l->name, "dispose") == 0)
				lua_pushcclosure(L, thunk_once, 1);
			else
				lua_pushcclosure(L, thunk, 1);
			lua_settable(L, methods);
		}

		// drop metatable and method table
		lua_pop(L, 2);
	}

	// call named lua method from userdata method table
	static int call(lua_State *L, const char *method,
					int nargs = 0, int nresults = LUA_MULTRET, int errfunc = 0)
	{
		// userdata index
		int base = lua_gettop(L) - nargs;
		if (!luaL_checkudata(L, base, T::className))
		{
			// drop userdata and args
			lua_settop(L, base - 1);
			lua_pushfstring(L, "not a valid %s userdata", T::className);
			return -1;
		}

		// method name
		lua_pushstring(L, method);
		// get method from userdata
		lua_gettable(L, base);
		if (lua_isnil(L, -1))
		{
			// no method?
			// drop userdata and args
			lua_settop(L, base - 1);
			lua_pushfstring(L, "%s missing method '%s'", T::className, method);
			return -1;
		}
		// put method under userdata, args
		lua_insert(L, base);

		// call method
		int status = lua_pcall(L, 1 + nargs, nresults, errfunc);
		if (status)
		{
			const char *msg = lua_tostring(L, -1);
			if (msg == NULL) msg = "(error with no message)";
			lua_pushfstring(L, "%s:%s status = %d\n%s",
							T::className, method, status, msg);
			// remove old message
			lua_remove(L, base);
			return -1;
		}
		// number of results
		return lua_gettop(L) - base + 1;
	}

	// push onto the Lua stack a userdata containing a pointer to T object
	static int push(lua_State *L, T *obj, bool gc = false)
	{
		if (!obj) { lua_pushnil(L); return 0; }
		// 把给定索引指向的值的元表压入堆栈.
		// 如果索引无效，或是这个值没有元表,函数将返回 0
		// 并且不会向栈上压任何东西. lookup metatable in Lua registry
		luaL_getmetatable(L, T::className);
		if (lua_isnil(L, -1)) luaL_error(L, "%s missing metatable", T::className);
		int mt = lua_gettop(L);
		subtable(L, mt, "userdata", "v");
		userdataType *ud = static_cast<userdataType*>(pushuserdata(L, obj, sizeof(userdataType)));
		if (ud)
		{
			// store pointer to object in userdata
			ud->pT = obj;
			lua_pushvalue(L, mt);
			// 设置 userdata 的元表
			lua_setmetatable(L, -2);
			if (gc == false)
			{
				lua_checkstack(L, 3);
				subtable(L, mt, "do not trash", "k");
				lua_pushvalue(L, -2);
				lua_pushboolean(L, 1);
				lua_settable(L, -3);
				lua_pop(L, 1);
			}
		}
		lua_replace(L, mt);
		lua_settop(L, mt);
		// index of userdata containing pointer to T object
		return mt;
	}

	// get userdata from Lua stack and return pointer to T object
	static T *check(lua_State *L, int narg)
	{
		// luaL_checkudata检查在栈中指定位置的对象是否为带有给定名字的metatable的userdata.
		userdataType *ud =
			static_cast<userdataType*>(luaL_checkudata(L, narg, T::className));
		if (!ud) luaL_error(L, "not a userdata of %s", T::className);
		// pointer to T object
		return ud->pT;
	}

private:
	Lunar();  // hide default constructor

	// member function dispatcher
	static int thunk(lua_State *L)
	{
		// stack has userdata, followed by method args
		// get 'self', or if you prefer, 'this'
		T *obj = check(L, 1);
		// remove self so member function args start at index 1
		lua_remove(L, 1);
		// get member function from upvalue
		// registry 实现了全局的值,upvalue机制实现了与C static变量等价的东东,这种变量只能在特定的函数内可见.
		// 每当你在Lua中创建一个新的C函数,你可以将这个函数与任意多个 lupvalues 联系起来,
		// 每一个 upvalue 可以持有一个单独的Lua值.我们称这种一个C函数和她的upvalues的组合为闭包(closure).
		// lua_upvalueindex 是一个宏,用来产生一个upvalue 的假索引.这个假索引除了不在栈中之外,和其他的索引一样.
		// 表达式lua_upvalueindex(1)函数第一个upvalue的索引.
		RegType *l = static_cast<RegType*>(lua_touserdata(L, lua_upvalueindex(1)));
		// call member function
		return (obj->*(l->mfunc))(L);
	}

	// member function dispatcher
	static int thunk_once(lua_State *L)
	{
		// stack has userdata, followed by method args
		// get 'self', or if you prefer, 'this'
		T *obj = check(L, 1);
		lua_pushnil(L);
		//delete metatable
		lua_setmetatable(L, 1);
		// remove self so member function args start at index 1
		lua_remove(L, 1);
		// get member function from upvalue
		RegType *l = static_cast<RegType*>(lua_touserdata(L, lua_upvalueindex(1)));
		// call member function
		int rel = (obj->*(l->mfunc))(L);

		// clear weak table "userdata" and "do not trash" because of the memory pool 
		int e = lua_gettop(L);
		luaL_getmetatable(L, T::className);
		if (!lua_isnil(L, -1))
		{
			int mt = lua_gettop(L);
			lua_getfield(L, mt, "userdata");
			int ud = lua_gettop(L);
			lua_getfield(L, mt, "do not trash");
			int dnt = lua_gettop(L);

			// clear do not trash
			lua_pushlightuserdata(L, obj);
			lua_pushnil(L);
			lua_settable(L, dnt);

			// clear userdata
			lua_pushlightuserdata(L, obj);
			lua_pushnil(L);
			lua_settable(L, ud);
		}
		lua_settop(L, e);
		return rel;
	}

	// create a new T object and
	// push onto the Lua stack a userdata containing a pointer to T object
	static int new_T(lua_State *L)
	{
		// use classname:new(), instead of classname.new()
		lua_remove(L, 1);
		// call constructor for T objects
		T *obj = new T(L);
		// gc_T will not delete this object
		push(L, obj);
		// userdata containing pointer to T object
		return 1;
	}

	static int d_new_T(lua_State *L)
	{
		// use classname:new(), instead of classname.new()
		lua_remove(L, 1);
		// call constructor for T objects
		T *obj = new T(L);
		// gc_T will delete this object
		push(L, obj, true);
		// userdata containing pointer to T object
		return 1;
	}

	// garbage collection metamethod
	static int gc_T(lua_State *L)
	{
		// 把来自索引 1 处的对象的元表的字段 do not trash 压栈.
		// 如果对象没有元表或其元表没有该字段,则返回0且不回压栈任何东西.
		if (luaL_getmetafield(L, 1, "do not trash"))
		{
			// dup userdata
			lua_pushvalue(L, 1);
			// 把 t[k] 值压入堆栈,这里的 t 是指有效索引 index 指向的值,而 k 则是栈顶放的值.
			// 这个函数会弹出堆栈上的 key(把结果放在栈上相同位置).
			lua_gettable(L, -2);
			if (!lua_isnil(L, -1)) return 0;  // do not delete object
		}
		userdataType *ud = static_cast<userdataType*>(lua_touserdata(L, 1));
		T *obj = ud->pT;
		// call destructor for T objects
		if (obj) delete obj;
		return 0;
	}

	static int tostring_T(lua_State *L)
	{
		char buff[32];
		userdataType *ud = static_cast<userdataType*>(lua_touserdata(L, 1));
		T *obj = ud->pT;
		sprintf(buff, "%p", (void*)obj);
		lua_pushfstring(L, "%s (%s)", T::className, buff);

		return 1;
	}

	static void set(lua_State *L, int table_index, const char *key)
	{
		lua_pushstring(L, key);
		// swap value and key
		lua_insert(L, -2);
		lua_settable(L, table_index);
	}

	static void weaktable(lua_State *L, const char *mode)
	{
		lua_newtable(L);
		// table is its own metatable
		lua_pushvalue(L, -1);
		// 把一个 table 弹出堆栈,并将其设为给定索引处的值的 metatable.
		lua_setmetatable(L, -2);
		// 本宏等价于lua_pushlstring,但是只能当s是字面字符串时使用,在这些情况下,它自动地提供字符串长度.
		lua_pushliteral(L, "__mode");
		lua_pushstring(L, mode);
		// metatable.__mode = mode
		lua_settable(L, -3);
	}

	static void subtable(lua_State *L, int tindex, const char *name, const char *mode)
	{
		lua_pushstring(L, name);
		// 把 t[k] 值压入堆栈,这里的 t 是指有效索引 index 指向的值,而 k 则是栈顶放的值.
		// 这个函数会弹出堆栈上的 key (把结果放在栈上相同位置).在 Lua 中,
		// 这个函数可能触发对应 "index" 事件的元方法.
		lua_gettable(L, tindex);
		if (lua_isnil(L, -1))
		{
			lua_pop(L, 1);
			lua_checkstack(L, 3);
			weaktable(L, mode);
			lua_pushstring(L, name);
			lua_pushvalue(L, -2);
			lua_settable(L, tindex);
		}
	}

	static void *pushuserdata(lua_State *L, void *key, size_t sz)
	{
		void *ud = 0;
		lua_pushlightuserdata(L, key);
		// lookup[key]
		lua_gettable(L, -2);
		if (lua_isnil(L, -1))
		{
			// drop nil
			lua_pop(L, 1);
			// 确保堆栈上至少有 extra 个空位.如果不能把堆栈扩展到相应的尺寸,函数返回 false.
			// 这个函数永远不会缩小堆栈;如果堆栈已经比需要的大了,那么就放在那里不会产生变化.
			lua_checkstack(L, 3);
			// 这个函数分配分配一块指定大小的内存块,把内存块地址作为一个完整的 userdata 压入堆栈,并返回这个地址.
			ud = lua_newuserdata(L, sz);
			lua_pushlightuserdata(L, key);
			// dup userdata
			lua_pushvalue(L, -2);
			// lookup[key] = userdata
			lua_settable(L, -4);
		}
		return ud;
	}
};

#define LUNAR_DECLARE_METHOD(Class, Name) \
	{#Name, &Class::Name}

#define LUNAR_DECLARE_CLASS(Class) \
	static char className[]; \
	Class(lua_State* pState); \
	static Lunar<Class>::RegType methods[]

#define LUNAR_IMPLEMENT_CLASS(Class) \
	char Class::className[] = #Class; \
	Class::Class(lua_State* pState) { assert(false); } \
	Lunar<Class>::RegType Class::methods[] =

#endif
