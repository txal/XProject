#include "dirent.h"

#ifdef _WIN32

DIR *opendir(const char *name)
{
	DIR *dir;
	WIN32_FIND_DATA FindData;
	char namebuf[512];

	sprintf(namebuf, "%s\\*.*", name);

	HANDLE hFind = FindFirstFile(namebuf, &FindData);
	if (hFind == INVALID_HANDLE_VALUE)
	{
		printf("FindFirstFile failed (%d)\n", GetLastError());
		return 0;
	}

	dir = (DIR *)malloc(sizeof(DIR));
	if (!dir)
	{
		printf("DIR memory allocate fail\n");
		return 0;
	}

	memset(dir, 0, sizeof(DIR));
	dir->dd_fd = hFind;

	return dir;
}

struct dirent *readdir(DIR *d)
{
	if (!d)
	{
		return 0;
	}
	WIN32_FIND_DATA FileData;
	BOOL bf = FindNextFile(d->dd_fd, &FileData);
	//fail or end  
	if (!bf)
	{
		return 0;
	}

	static struct dirent dirent;
	for (int i = 0; i < 256; i++)
	{
		dirent.d_name[i] = FileData.cFileName[i];
		if (FileData.cFileName[i] == '\0') break;
	}
	dirent.d_reclen = (uint16_t)FileData.nFileSizeLow;

	//check there is file or directory  
	if (FileData.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY)
	{
		dirent.d_type = 2;
	}
	else
	{
		dirent.d_type = 1;
	}

	return &dirent;
}

int closedir(DIR *d)
{
	if (!d) return -1;
	free(d);
	return 0;
}

#endif