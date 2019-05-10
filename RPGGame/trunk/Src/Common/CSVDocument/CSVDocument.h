#ifndef __CSV_MANAGER_H__
#define __CSV_MANAGER_H__

#include "Common/Platform.h"
#include "Variant.hpp"

//CSV列
class CSVColumn 
{
public:
	CSVColumn(const std::string &str);
	~CSVColumn();
	//返回列名称
	inline const std::string& columnName() const { return m_sName; }
	inline int size() const { return (int)m_RowValue.size();  }
public:
	std::string m_sName;//列名称
	std::vector<Variant*> m_RowValue; //行值
};

//CSV文档
class CSVDocument
{
public:
	typedef std::map<std::string, CSVColumn*> ColumnMap;
	typedef ColumnMap::const_iterator ColumnMapIter;

public:
	CSVDocument() {}
	~CSVDocument();
	//从数据流加载CSV文档
	void load(const std::string& oFile, bool bWithHeader = true, int *errorRow = NULL, int *errorCol = NULL);
	//返回CSV文档行数量
	inline size_t numRows() const { return m_dwRowNum; }
	//返回CSV文档列数量
	inline size_t numColumns() const { return m_dwColNum; }
	//获取列名索引
	int getColumnIndex(const std::string &columnName) const;
	//读取第rowIndex行columnName列的数据
	Variant getValue(const size_t rowIndex , const std::string& columnName) const;
	//读取第rowIndex行columnIndex列的数据
	Variant getValue(const size_t rowIndex, const size_t columnIndex) const;

protected:
	std::vector<CSVColumn*> m_ColumnList;//以索引为下标的CSV列对象表
	ColumnMap m_ColumnMap;//以列名称为索引的CSV列对象表

	size_t m_dwColNum; //文档列数
	size_t m_dwRowNum; //文档行数
private:
	void parseColumns(const std::string &str, char target);
	bool parseRow(const std::string &rowStr, char target, int *errorCol = NULL);
	void clearColumnObject();
	std::string transferString(char* str, int strLen); //处理引号问题
};

//CSV文档读取游标
class CSVCursor
{
public:
	CSVCursor();
	~CSVCursor();
	//设置文档对象并转到第rowIndex行
	void setDocument(CSVDocument *document, size_t rowIndex = 0);
	//返回当前行索引
	inline size_t rowIndex() const { return m_nRowIndex; }
	//设置当前行索引
	void setRowIndex(const size_t index);
	//转到第一行
	void first();
	//转到最后一行
	void last();
	//转到下一行
	void next();
	//是否到达结束行（行索引>=文档行的数量)
	bool eof() const;
	//通过列名称读取数据
	inline Variant getValue(const std::string& columnName) const
	{ return m_pDocument->getValue(m_nRowIndex, columnName); }
	//通过列索引读取数据
	inline Variant getValue(const size_t columnIndex) const
	{ return m_pDocument->getValue(m_nRowIndex, columnIndex); }

protected:
	CSVDocument *m_pDocument;//CSV文档对象
	size_t m_nRowIndex;//当前数据行索引
};

#endif