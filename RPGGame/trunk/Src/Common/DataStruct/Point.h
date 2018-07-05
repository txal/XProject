#ifndef __POINT_H__
#define __POINT_H__

#include "Common\DataStruct\XMath.h"

class Point
{
public:	
	int x;
	int y;
public:
	Point(int _x = -1, int _y = -1)
	{
		x = _x;
		y = _y;
	}
	void Reset()
	{
		x = -1;
		y = -1;
	}
	bool IsValid()
	{
		return (x >= 0 && y >= 0);
	}
	bool operator==(const Point& oPos)
	{
		return (oPos.x == x && oPos.y == y);
	}
	Point operator-(const Point& oPos) const
	{
		return Point(x - oPos.x, y - oPos.y);
	}
	Point operator+(const Point& oPos)
	{
		return Point(x + oPos.x, y + oPos.y);
	}
	int Distance(const Point& oPos) const
	{
		int nDistX = x - oPos.x;
		int nDistY = y - oPos.y;
		int nDist = (int)sqrt(nDistX * nDistX + nDistY * nDistY);
		return nDist;
	}
	bool CheckDistance(const Point& oTarPos, const Point& oDistance) const
	{
		int dx = (int)abs(x - oTarPos.x);
		int dy = (int)abs(y - oTarPos.y);
		if (dx > oDistance.x || dy > oDistance.y)
		{
			return false;
		}
		return true;
	}
};

#endif
