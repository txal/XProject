#ifndef __BATTLE_UTIL_H__
#define __BATTLE_UTIL_H__

#include "Common/Platform.h"
#include "Server/LogicServer/GameObject/Actor.h"
#include "Server/LogicServer/ConfMgr/ConfMgr.h"

#define PI 3.141592653589793238462643383279502884
static int gtDir[8][2] = { { 0, 1 }, { 0, -1 }, { -1, 0 }, { 1, 0 }, { -1, 1 }, { 1, 1 }, { 1, -1 }, { -1, -1 } };

namespace BattleUtil
{
	//计算弧度(x1,y1原点)
	inline float CalcRadian(int nX1, int nY1, int nX2, int nY2)
	{
		int nWidth = nX2 - nX1;
		int nHeight = nY2 - nY1;
		double dRadian = atan2(nHeight, nWidth);
		return (float)dRadian;
	}

	//计算角度(x1,y1原点)
	inline float CalcDegree(int nX1, int nY1, int nX2, int nY2)
	{
		double dRadian = BattleUtil::CalcRadian(nX1, nY1, nX2, nY2);
		double dDegree = dRadian * (180.0 / PI);
		dDegree = dDegree < 0 ? (360 + dDegree) : dDegree;
		return (float)dDegree;
	}

	//直线坐标检测
	inline bool FixLineMovePoint(MAPCONF* poMapConf, int nStartPosX, int nStartPosY, int& nTarPosX, int& nTarPosY, Actor* poActor)
	{
		if (poMapConf == NULL)
		{
			return false;
		}
		bool bResult = true;
		int nMapWidthPixel = poMapConf->nPixelWidth;
		int nMapHeightPixel = poMapConf->nPixelHeight;
		if (nStartPosX < 0)
		{
			nStartPosX = 0;
			bResult = false;
		}
		else if (nStartPosX >= nMapWidthPixel)
		{
			nStartPosX = nMapWidthPixel - 1;
			bResult = false;
		}
		if (nStartPosY < 0)
		{
			nStartPosY = 0;
			bResult = false;
		}
		else if (nStartPosY >= nMapHeightPixel)
		{
			nStartPosY = nMapHeightPixel - 1;
			bResult = false;
		}

		bool bXOut = false;
		bool bYOut = false;
		if (nTarPosX < 0)
		{
			nTarPosX = 0;
			bXOut = true;
		}
		else if (nTarPosX >= nMapWidthPixel)
		{
			nTarPosX = nMapWidthPixel - 1;
			bXOut = true;
		}
		if (nTarPosY < 0)
		{
			nTarPosY = 0;
			bYOut = true;
		}
		else if (nTarPosY >= nMapHeightPixel)
		{
			nTarPosY = nMapHeightPixel - 1;
			bYOut = true;
		}
		if (bXOut && bYOut)
		{
			bResult = false;
		}
		return bResult;

		//double fUnitX = (double)nStartPosX / gnUnitWidth;
		//double fUnitY = (double)nStartPosY / gnUnitHeight;
		//double fUnitTarX = (double)nTarPosX / gnUnitWidth;
		//double fUnitTarY = (double)nTarPosY / gnUnitHeight;
		//if ((int)fUnitX == (int)fUnitTarX && (int)fUnitY == (int)fUnitTarY)
		//{
		//	return bResult;
		//}
		//bool bInBlockUnit = poMapConf->IsBlockUnit((int)fUnitX, (int)fUnitY);
		//double fDistUnitX = fUnitTarX - fUnitX;
		//double fDistUnitY = fUnitTarY - fUnitY;
		//int nDistUnitMax = XMath::Max(1, XMath::Max((int)ceil(abs(fDistUnitX)), (int)ceil(abs(fDistUnitY))));
		//fDistUnitX = fDistUnitX / nDistUnitMax;
		//fDistUnitY = fDistUnitY / nDistUnitMax;

		//double fOrgUnitX = fUnitX, fOrgUnitY = fUnitY;
		//for (int i = nDistUnitMax - 1; i > -1; --i)
		//{
		//	double fNewUnitX = fUnitX + fDistUnitX;
		//	double fNewUnitY = fUnitY + fDistUnitY;

		//	int8_t nMasks = 0;
		//	if (fNewUnitX >= 0 && fNewUnitX < poMapConf->nUnitNumX && fNewUnitY >= 0 && fNewUnitY < poMapConf->nUnitNumY)
		//	{
		//		nMasks = 1;
		//	}
		//	if (nMasks == 0)
		//	{
		//		bResult = false;
		//	}
		//	else if (!bInBlockUnit)
		//	{
		//		bool bBlockUnit = poMapConf->IsBlockUnit((int)fNewUnitX, (int)fNewUnitY);
		//		if (bBlockUnit)
		//		{
		//			bResult = false;
		//		}
		//		//else
		//		//{//对角线判断
		//		//	int nDistX = abs((int)fUnitX - (int)fNewUnitX);
		//		//	int nDistY = abs((int)fUnitY - (int)fNewUnitY);
		//		//	if (nDistX == 1 && nDistY == 1)
		//		//	{
		//		//		if (poMapConf->IsBlockUnit((int)fUnitX, (int)fNewUnitY)
		//		//			|| poMapConf->IsBlockUnit((int)fNewUnitX, (int)fUnitY))
		//		//		{
		//		//			bResult = false;
		//		//		}
		//		//	}
		//		//}
		//		//if (poActor == NULL || poActor->GetType() == eOT_Robot)
		//		//{
		//		//	XDebug("####0.5 %s %s %f %f %f %f %f %f %d %d\n", bBlockUnit ? "true" : "false", bResult ? "true" : "false", fUnitX, fUnitY, fNewUnitX, fNewUnitY, fUnitTarX, fUnitTarY, nTarPosX, nTarPosY);
		//		//}
		//	}
		//	if (bResult)
		//	{
		//		fUnitX = fNewUnitX;
		//		fUnitY = fNewUnitY;
		//	}
		//	else
		//	{
		//		if (fUnitX != fOrgUnitX ||  fUnitY != fOrgUnitY)
		//		{
		//			nTarPosX = (int)(fUnitX * gnUnitWidth);
		//			nTarPosY = (int)(fUnitY * gnUnitHeight);
		//		}
		//		else
		//		{
		//			nTarPosX = nStartPosX;
		//			nTarPosY = nStartPosY;
		//		}
		//		break;
		//	}
		//}
		////if (poActor == NULL || poActor->GetType() == eOT_Robot)
		////{
		////	XDebug("####1 %s %d %d %d %d %f %f\n", bResult ? "true" : "false", nStartPosX, nStartPosY, nTarPosX, nTarPosY, fDistUnitX, fDistUnitY);
		////}
		//return bResult;
	}

	//计算方向
	inline int CalcDir8(const Point& oSrcPos, const Point& oTarPos)
	{
		if (oTarPos.y < oSrcPos.y)
		{
			if (oTarPos.x < oSrcPos.x)
			{
				return eDT_LeftBottom;
			}
			if (oTarPos.x > oSrcPos.x)
			{
				return eDT_RightBottom;
			}
			return eDT_Bottom;
		}
		else if (oTarPos.y > oSrcPos.y)
		{
			if (oTarPos.x < oSrcPos.x)
			{
				return eDT_LeftTop;
			}
			if (oTarPos.x > oSrcPos.x)
			{
				return eDT_RightTop;
			}
			return eDT_Top;
		}
		else
		{
			if (oTarPos.x < oSrcPos.x)
			{
				return eDT_Left;
			}
			if (oTarPos.x > oSrcPos.x)
			{
				return eDT_Right;
			}
		}
		return eDT_None;//ERROR nTarPosX,nTarPosY == oCurrPos
	}

	//计算移动速度
	inline void CalcMoveSpeed(int nMoveSpeed, int nDir8, int& nSpeedX, int& nSpeedY)
	{
		assert(nMoveSpeed >= 0);
		switch (nDir8)
		{
			case eDT_Top:
				nSpeedX = 0;
				nSpeedY = nMoveSpeed;
				break;
			case eDT_RightTop:
				nSpeedX = nMoveSpeed;
				nSpeedY = nMoveSpeed;
				break;
			case eDT_Right:
				nSpeedX = nMoveSpeed;
				nSpeedY = 0;
				break;
			case eDT_RightBottom:
				nSpeedX = nMoveSpeed;
				nSpeedY = -nMoveSpeed;
				break;
			case eDT_Bottom:
				nSpeedX = 0;
				nSpeedY = -nMoveSpeed;
				break;
			case eDT_LeftBottom:
				nSpeedX = -nMoveSpeed;
				nSpeedY = -nMoveSpeed;
				break;
			case eDT_Left:
				nSpeedX = -nMoveSpeed;
				nSpeedY = 0;
				break;
			case eDT_LeftTop:
				nSpeedX = -nMoveSpeed;
				nSpeedY = nMoveSpeed;
				break;
			default:
				nSpeedX = 0;
				nSpeedY = 0;
				break;
		}
		if (nSpeedX == 0)
		{
			nSpeedY = (int)(nSpeedY * 0.7f);
		}
		else if (nSpeedY != 0)
		{
			nSpeedY = (int)(nSpeedY * 0.4f);
			nSpeedX = (int)(nSpeedX * 0.9f);
		}
	}

	//计算移动速度(勾股定理)
	inline void CalcMoveSpeed1(int nMoveSpeed, const Point& oSrcPos, const Point& oTarPos, int& nSpeedX, int& nSpeedY)
	{
		assert(nMoveSpeed >= 0);
		int nDistX = oTarPos.x - oSrcPos.x;
		int nDistY = oTarPos.y - oSrcPos.y;
		if (nDistX == 0 && nDistY == 0)
		{
			nSpeedX = 0;
			nSpeedY = 0;
			return;
		}
		if (nDistY == 0)
		{
			nSpeedX = (int)(nMoveSpeed*0.7f);
			nSpeedY = 0;
			return;
		}
		if (nDistX == 0)
		{
			nSpeedX = 0;
			nSpeedY = nMoveSpeed;
			return;
		}
		float fAngle = BattleUtil::CalcRadian(oSrcPos.x, oSrcPos.y, oTarPos.x, oTarPos.y);
		float fCos = cos(fAngle);
		float fSin = sin(fAngle);
		nSpeedX = (int)(fCos * nMoveSpeed);
		nSpeedY = (int)(fSin * nMoveSpeed);
	}

	//计算移动时间(秒)
	inline float CalcMoveTime(int nMoveSpeed, const Point& oSrcPos, const Point& oTarPos)
	{
		if (nMoveSpeed <= 0)
		{
			return 0.1f;
		}

		int nSpeedX = 0;
		int nSpeedY = 0;
		CalcMoveSpeed(nMoveSpeed, CalcDir8(oSrcPos, oTarPos), nSpeedX, nSpeedY);

		int nMinMoveSpeed = (int)(nMoveSpeed * 0.6f);
		if (nSpeedY < 0 && nSpeedY > -nMinMoveSpeed)
		{
			nSpeedY = -nMinMoveSpeed;
		}
		else if (nSpeedY > 0 && nSpeedY < nMinMoveSpeed)
		{
			nSpeedY = nMinMoveSpeed;
		}

		float fTimeX = (nSpeedX != 0) ? fabs((oTarPos.x - oSrcPos.x) / (float)nSpeedX) : 0.0f;
		float fTimeY = (nSpeedY != 0) ? fabs((oTarPos.y - oSrcPos.y) / (float)nSpeedY) : 0.0f;
		float fMaxTime = (fTimeX > fTimeY) ? fTimeX : fTimeY;
		fMaxTime = XMath::Max(0.1f, fMaxTime);
		return fMaxTime;
	}


	//计算移动时间1(秒,勾股定理)
	inline float CalcMoveTime1(int nMoveSpeed, const Point& oSrcPos, const Point& oTarPos)
	{
		if (nMoveSpeed <= 0)
		{
			return 0.1f;
		}

		int nSpeedX = 0;
		int nSpeedY = 0;
		CalcMoveSpeed1(nMoveSpeed, oSrcPos, oTarPos, nSpeedX, nSpeedY);

		float fTimeX = (nSpeedX != 0) ? fabs((oTarPos.x - oSrcPos.x) / (float)nSpeedX) : 0.0f;
		float fTimeY = (nSpeedY != 0) ? fabs((oTarPos.y - oSrcPos.y) / (float)nSpeedY) : 0.0f;
		float fMaxTime = (fTimeX > fTimeY) ? fTimeX : fTimeY;
		fMaxTime = XMath::Max(0.1f, fMaxTime);
		return fMaxTime;
	}


	inline int GetUnitUnderPoint(float fUnitX, float fUnitY, Point* tUnitList)
	{
		int nCount = 0;
		bool bIsIntX = fUnitX == (int)fUnitX ? true : false;
		bool bIsIntY = fUnitY == (int)fUnitY ? true : false;
		if (bIsIntX && bIsIntY)
		{
			tUnitList[0].x = (int)(fUnitX - 1);
			tUnitList[0].y = (int)(fUnitY - 1);
			tUnitList[1].x = (int)fUnitX;
			tUnitList[1].y = (int)(fUnitY - 1);
			tUnitList[2].x = (int)(fUnitX - 1);
			tUnitList[2].y = (int)fUnitY;
			tUnitList[3].x = (int)fUnitX;
			tUnitList[3].y = (int)fUnitY;
			nCount = 4;
		}
		else if (bIsIntX && !bIsIntY)
		{
			tUnitList[0].x = (int)(fUnitX - 1);
			tUnitList[0].y = (int)fUnitY;
			tUnitList[1].x = (int)fUnitX;
			tUnitList[1].y = (int)fUnitY;;
			nCount = 2;
		}
		else if (!bIsIntX && bIsIntY)
		{
			tUnitList[0].x = (int)fUnitX;
			tUnitList[0].y = (int)(fUnitY - 1);
			tUnitList[1].x = (int)fUnitX;
			tUnitList[1].y = (int)fUnitY;
			nCount = 2;
		}
		else
		{
			tUnitList[0].x = (int)fUnitX;
			tUnitList[0].y = (int)fUnitY;
			nCount = 1;
		}
		return nCount;
	}


	inline bool FloydCrossAble(MAPCONF* poMapConf, int nPosX1, int nPosY1, int nPosX2, int nPosY2)
	{
		int nUnitX1 = nPosX1 / gnUnitWidth;
		int nUnitY1 = nPosY1 / gnUnitHeight;
		int nUnitX2 = nPosX2 / gnUnitWidth;
		int nUnitY2 = nPosY2 / gnUnitHeight;

		if (nUnitX1 == nUnitX2 && nUnitY1 == nUnitY2)
		{
			return true;
		}
		float fUnitCenterX1 = nUnitX1 + 0.5f;
		float fUnitCenterY1 = nUnitY1 + 0.5f;
		float fUnitCenterX2 = nUnitX2 + 0.5f;
		float fUnitCenterY2 = nUnitY2 + 0.5f;
		int nLoopDir = 1;
		if (abs((int)(nUnitX2 - nUnitX1)) <= abs((int)(nUnitY2 - nUnitY1)))
		{
			nLoopDir = 2;
		}
		float fDistX = fUnitCenterX1 - fUnitCenterX2;
		fDistX = fDistX == 0 ? 1 : fDistX;
		float fA = (fUnitCenterY1 - fUnitCenterY2) / fDistX;
		float fB = fUnitCenterY1 - fA * fUnitCenterX1;
		if (nLoopDir == 1)
		{
			Point tUnitList[4];
			float fLoopStart = (float)XMath::Min(nUnitX1, nUnitX2);
			float fLoopStartCenter = fLoopStart + 0.5f;
			float fLoopEnd = (float)XMath::Max(nUnitX1, nUnitX2);
			for (float i = fLoopStart; i <= fLoopEnd; i++)
			{
				if (i == fLoopStart)
				{
					i += 0.5f;
				}
				float fPosY = 0;
				if (fUnitCenterX1 == fUnitCenterX2)
				{
					assert(false);
					return false;
				}
				else if (fUnitCenterY1 == fUnitCenterY2)
				{
					fPosY = fUnitCenterY1;
				}
				else
				{
					fPosY = fA * i + fB;
				}
				int nCount = GetUnitUnderPoint(i, fPosY, tUnitList);
				for (int n = nCount - 1; n >= 0; n--)
				{
					if (poMapConf->IsBlockUnit(tUnitList[n].x, tUnitList[n].y))
					{
						return false;
					}
				}
				if (i == fLoopStartCenter)
				{
					i -= 0.5f;
				}
			}
		}
		else
		{
			Point tUnitList[4];
			float fLoopStart = (float)XMath::Min(nUnitY1, nUnitY2);
			float fLoopStartCenter = fLoopStart + 0.5f;
			float fLoopEnd = (float)XMath::Max(nUnitY1, nUnitY2);
			for (float i = fLoopStart; i <= fLoopEnd; i++)
			{
				if (i == fLoopStart)
				{
					i += 0.5f;
				}
				float fPosX = 0;
				if (fUnitCenterX1 == fUnitCenterX2)
				{
					fPosX = fUnitCenterX1;
				}
				else if (fUnitCenterY1 == fUnitCenterY2)
				{
					assert(false);
					return false;
				}
				else
				{
					fPosX = (i - fB) / fA;
				}
				int nCount = GetUnitUnderPoint(fPosX, i, tUnitList);
				for (int n = nCount - 1; n >= 0; n--)
				{
					if (poMapConf->IsBlockUnit(tUnitList[n].x, tUnitList[n].y))
					{
						return false;
					}
				}
				if (i == fLoopStartCenter)
				{
					i -= 0.5f;
				}
			}
		}
		return true;
	}

	//位置误差是否可接受
	inline bool IsAcceptablePositionFaultBit(int nPosX1, int nPosY1, int nPosX2, int nPosY2)
	{
		static int nAcceptableX = gnUnitWidth * gnTowerWidth;
		static int nAcceptableY = gnUnitHeight * gnTowerHeight;

		int nDistX = abs(nPosX2 - nPosX1);
		int nDistY = abs(nPosY2 - nPosY1);
		return (nDistX < nAcceptableX && nDistY < nAcceptableY);
	}

}

#endif
