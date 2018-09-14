#ifndef __MEMORY_H__
#define __MEMORY_H__

#ifdef __linux
	#include "Include/Jemalloc/Jemalloc.hpp"
#endif

#define XNEW(class) new class
#define XALLOC realloc
#define SAFE_FREE(ptr)  if ((ptr) != NULL) { free(ptr); (ptr) = NULL; }
#define SAFE_DELETE(ptr)  if ((ptr) != NULL) { delete (ptr); (ptr) = NULL; }
#define SAFE_DELETE_ARRAY(ptr)  if ((ptr) != NULL) { delete[] (ptr); (ptr) = NULL; }

#endif