#ifndef __MEMORYPOLL_H__
#define __MEMORYPOLL_H__

#include "stl_alloc.h"
#include <assert.h>

template<class T>
class CMemPool {
	public:
		static void*
		operator new(size_t alloc_len) throw() {
			assert(sizeof(T) == alloc_len);
			assert(sizeof(T) >= sizeof(unsigned char*));
			void *return_pointer = alloc::allocate(alloc_len);
			return return_pointer;
		 }

		static void 
		operator delete(void *delete_pointer) {
			if(NULL == delete_pointer) return;
			alloc::deallocate(delete_pointer, sizeof(T));
		}
	protected:
		explicit CMemPool(void) {}
		~CMemPool(void) {}
};

#endif
