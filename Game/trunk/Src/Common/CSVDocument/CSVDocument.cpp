#include "CSVDocument.h"
#include <fstream>

static Variant NullVar;

CSVColumn::CSVColumn(const std::string &str)
{
	m_sName = str;
}

CSVColumn::~CSVColumn()
{
	for (int i = 0; i < (int)m_RowValue.size(); i++)
	{
		delete m_RowValue[i];
	}
}

void CSVDocument::load(const std::string& oFile, bool bWithHeader /* = true */, int *errorRow /* = NULL */, int *errorCol /* = NULL */)
{
	std::ifstream oStream(oFile.c_str(), std::ios::in) ;
	if (!oStream.is_open())
	{
		printf("打开文件失败: %s\n", oFile.c_str());
		return;
	}
	std::vector<std::string> stringList;
	char sBuff[1024];
	while (!oStream.eof())
	{
		memset(sBuff, 0, sizeof(sBuff));
		oStream.getline(sBuff, sizeof(sBuff));
		if (sBuff[0] != '\0')
		{
			int len = (int)strlen(sBuff);
			if (sBuff[len - 1] == '\r')
				sBuff[len - 1] = '\0';
			stringList.push_back(sBuff);
		}
	}
	//首先清空现有数据
	clearColumnObject();
	//文档为空，没有数据则退出
	if (stringList.size() <= 0)
		return;

	//从第0行分析列名称表，分隔符是","
	parseColumns(stringList[0], ',');

	//循环读取数据并添加到每个列对象
	const int rowCount = (int)stringList.size();
	m_dwRowNum = 0;
	int hadErrCol = 0;
	int nStartRow = bWithHeader ? 1 : 0;
	for (int i = nStartRow; i < rowCount; ++i)
	{
		if (parseRow(stringList[i], ',', &hadErrCol))
		{
			m_dwRowNum++;
		}
		if (hadErrCol != 0)
		{
			if (errorRow && errorCol)
			{
				*errorCol = hadErrCol;
				*errorRow = i;
				return;
			}
			else assert(false);
		}
	}
#ifdef _DEBUG
	for (size_t i = 0; i < m_dwColNum; ++i)
	{
		if ((int)m_dwRowNum != m_ColumnList[i]->size())
		{
			if (errorCol)
			{
				*errorCol = (int)i;
				return;
			}
			else
			{
				assert(false);
			}
		}
	}
#endif
}

void CSVDocument::clearColumnObject()
{

	for (int i = 0; i < (int)m_ColumnList.size(); i++)
	{
		SAFE_DELETE(m_ColumnList[i]);
	}
	m_ColumnList.clear();
	m_ColumnMap.clear();
}

void CSVDocument::parseColumns(const std::string &str, char target)
{
	const char *srcStr = str.c_str();
	if (NULL == srcStr)
		return;
	while (true)
	{
		const char *pBreak = strchr(srcStr, target);
		if (NULL == pBreak)
		{
			const char *tmp = srcStr;
			while (*tmp != '\0')
				tmp++;
			CSVColumn *newColumn = XNEW(CSVColumn)(std::string(srcStr, tmp - srcStr));
			m_ColumnMap[std::string(srcStr, tmp - srcStr)] = newColumn;
			m_ColumnList.push_back(newColumn);
			break;
		}
		if (*pBreak != *srcStr) //都不是','的情况
		{
			CSVColumn *newColumn = XNEW(CSVColumn)(std::string(srcStr, pBreak - srcStr));
			m_ColumnMap[std::string(srcStr, pBreak - srcStr)] = newColumn;
			m_ColumnList.push_back(newColumn);
		}
		srcStr = pBreak + 1;
	}

	m_dwColNum = m_ColumnList.size();
}

static double __s2d__(const char* s, char** e)
{
	double result = 0, dotValue;
	bool dot = false, neg = false;
	if (e) *e = NULL;

	unsigned int ch = *s;
	if (ch == '-')
	{
		neg = true;
		s++;
	}
	else result = 0;

	while (true)
	{
		unsigned int ch = *s;
		if (!ch)
			break;
		if (ch >= '0' && ch <= '9')
		{
			if (!dot)
			{
				result *= 10;
				result += ch - '0';
			}
			else
			{
				result += (ch - '0') * dotValue;
				dotValue *= 0.1;
			}
		}
		else if (ch == '.')
		{
			if (!dot)
			{
				dot = true;
				dotValue = 0.1;
			}
			else
			{
				if (e) *e = (char*)s;
				break;
			}
		}
		else
		{
			if (e) *e = (char*)s;
			break;
		}
		s++;
	}

	return !neg ? result : -result;
}

bool CSVDocument::parseRow(const std::string &rowStr, char target, int *errorCol /* = NULL */)
{
	const size_t slen = rowStr.length();
	if (slen <= 1)
		return false;//没数据或数据太短也不管
	const char *srcStr = rowStr.c_str();
	if (slen >= 2 && srcStr[0] == '/' && srcStr[1] == '/')
		return false;	//如果头两个字符 是  //  代表该行无效
	if (slen > 1 && srcStr[0] == ',' && srcStr[1] == ',')
		return false;   //如果头两个字符都是‘，’表示该行数据无效
	const char cTrans = '"';//特殊转义符
	short i = 0;
	while (true)
	{
		if (i >= (int)m_ColumnList.size())
			break;
		char *pBreak;
		if (*srcStr == cTrans)
		{
			pBreak = (char*)strchr(srcStr + 1, cTrans);
			while (pBreak != NULL && *(pBreak + 1) == cTrans)
			{
				pBreak = (char*)strchr(pBreak + 2, cTrans);
			}

			if (pBreak == NULL || (*(pBreak + 1) != target && *(pBreak + 1) != '\0'))
			{
				//这不可能发生，数据错误了
				if (errorCol != NULL)
				{
					*errorCol = i;
					return false;
				}
				else
				{
					assert(false);
				}
			}

			++pBreak;
			if (*pBreak == '\0')
			{
				pBreak = NULL;
			}
		}
		else
		{
			pBreak = (char*)strchr(srcStr, target);
		}

		CSVColumn* column = m_ColumnList[i];
		if (NULL == pBreak)
		{
			const char *tmp = srcStr;
			while (*tmp != '\0')
				tmp++;
			char* err = NULL;
			double dVal = __s2d__(srcStr, &err);
			Variant *var = XNEW(Variant);
			if (!err || *err == '\0')
			{
				*var = dVal;
			}
			else
			{
				*var = transferString((char*)srcStr, (int)(tmp - srcStr));
			}
			column->m_RowValue.push_back(var);
			break;
		}
		if (*srcStr == *pBreak)
		{
			Variant *var = XNEW(Variant);
			column->m_RowValue.push_back(var);
		}
		else
		{
			//先尝试将字符串转换为浮点数，通常情况下，CSV配置表中
			//用于配置数字。如果内容能够被转换为浮点数，则可以节约
			//更多的内存空间并提高性能。如果只无法被转换为浮点数，
			//则再存储为std::string。
			char* err = NULL;
			double dVal = __s2d__(srcStr, &err);
			Variant *var = XNEW(Variant);
			if (!err || err >= pBreak)
			{
				*var = dVal;
			}
			else
			{
				*var = transferString((char*)srcStr, (int)(pBreak - srcStr));
			}
			column->m_RowValue.push_back(var);
		}

		srcStr = pBreak + 1;
		i++;
	}
	return true;
}

std::string CSVDocument::transferString(char* sdata, int strLen)
{
	//可能需要考虑到编码问题
	const char cTrans = '"';
	//char* sdata = (char*)str.ptr();
	if (*sdata != cTrans)
	{
		return std::string(sdata, strLen);
	}

	//去除两边引号
	int len = strLen;
	int cLen = sizeof(cTrans);
	int rLen = 2 * cLen;
	memcpy(sdata, sdata + sizeof(cTrans), len - rLen);

	char* pBreak = sdata;
	while ((pBreak = strchr(pBreak, cTrans)) != NULL && sdata + len - rLen > pBreak)
	{
		memcpy(pBreak, pBreak + cLen, sdata + len - pBreak - cLen);

		pBreak = pBreak + cLen;
		rLen += cLen;
	}

	return std::string(sdata, len - rLen);
}

int CSVDocument::getColumnIndex(const std::string &columnName) const
{
	const CSVColumn * const *colList = m_ColumnList.data();
	for (int i = (int)m_ColumnList.size() - 1; i > -1; --i)
	{
		if (colList[i]->columnName() == columnName)
			return i;
	}
	return -1;
}

Variant CSVDocument::getValue(const size_t rowIndex, const std::string& columnName) const
{
	ColumnMapIter iter = m_ColumnMap.find(columnName);
	if (iter == m_ColumnMap.end())
	{
		return NullVar;
	}
	if ((int)rowIndex >= iter->second->size())
	{
		return NullVar;
	}
	return *iter->second->m_RowValue[rowIndex];
}


Variant CSVDocument::getValue(const size_t rowIndex, const size_t columnIndex) const
{
	if (columnIndex >= m_ColumnList.size())
	{
		return NullVar;
	}
	const CSVColumn* column = m_ColumnList[columnIndex];
	if (!column || (int)rowIndex >= column->size())
	{
		return NullVar;
	}
	return *column->m_RowValue[rowIndex];
}

CSVCursor::CSVCursor()
{
	m_pDocument = NULL;
}

CSVCursor::~CSVCursor()
{
	setDocument(NULL);
}

void CSVCursor::setDocument(CSVDocument *document, size_t rowIndex /* = 0 */)
{
	if (m_pDocument != document)
	{
		if (m_pDocument)
		{
			SAFE_DELETE(m_pDocument);
		}
		m_pDocument = document;
	}
	m_nRowIndex = rowIndex;
}

void CSVCursor::setRowIndex(const size_t index)
{
	m_nRowIndex = index;
}

void CSVCursor::first()
{
	m_nRowIndex = 0;
}

void CSVCursor::last()
{
	m_nRowIndex = m_pDocument->numRows() - 1;
}

void CSVCursor::next()
{
	m_nRowIndex++;
}

bool CSVCursor::eof() const
{
	return m_nRowIndex >= m_pDocument->numRows() ? true : false;
}

