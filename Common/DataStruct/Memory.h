#ifndef __MEMORY_H__
#define __MEMORY_H__

#include <stdlib.h>

 #ifdef __linux
//Jemalloc 只要把静态库编译进来,就算不包含头文件,也会生效(realloc,malloc,newd等会被hook掉)
  #include "Include/Jemalloc/Jemalloc.hpp"
 #endif

#define XNEW(class) new class
#define XALLOC realloc
#define SAFE_FREE(ptr)  if ((ptr) != NULL) { free(ptr); (ptr) = NULL; }
#define SAFE_DELETE(ptr)  if ((ptr) != NULL) { delete (ptr); (ptr) = NULL; }
#define SAFE_DELETE_ARRAY(ptr)  if ((ptr) != NULL) { delete[] (ptr); (ptr) = NULL; }

#endif