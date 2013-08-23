//
//  geometry.h
//  PhotoKifuCore
//
//  Created by Francois Beaussier on 30/05/13.
//  Copyright (c) 2013 Francois Beaussier. All rights reserved.
//

#ifndef __PhotoKifuCore__geometry__
#define __PhotoKifuCore__geometry__

#include <iostream>

double dist(const cv::Point &p1, const cv::Point &p2);

double distanceBetweenLineAndPoint(const cv::Point &a, const cv::Point &b, const cv::Point &c);
double distanceBetweenLines(std::vector<cv::Point> line1, std::vector<cv::Point> line2);
double angle(const cv::Point& pt1, const cv::Point& pt2, const cv::Point& pt0);

bool intersection(const cv::Point &o1, const cv::Point &p1, const cv::Point &o2, const cv::Point &p2, cv::Point &r);

void normalFormToPoint(float rho, float thetaInDeg, cv::Point &pt1, cv::Point &pt2);
void pointsToNormalForm(const cv::Point &p1, const cv::Point &p2, float& rho, float& thetaInDeg);

bool vertical(const std::vector<std::vector<cv::Point>> &lines);
std::vector<std::vector<cv::Point>> selectExtremeLines(int minLineLength, const std::vector<std::vector<cv::Point>> &lineSegments);
std::vector<cv::Point> findMinMaxPoints(const std::vector<std::vector<cv::Point>> &linesA, const std::vector<std::vector<cv::Point>> &linesB);

template <class T> cv::Point2f getCenter(std::vector<T> points);

std::vector<cv::Point2f> sortSquarePointsClockwisef(std::vector<cv::Point> square);
std::vector<cv::Point> sortSquarePointsClockwise(std::vector<cv::Point> square);

cv::vector<cv::Point> sortPoints(const cv::vector<cv::Point> points);
cv::vector<cv::Point2f> sortPoints(const cv::vector<cv::Point2f> points);

cv::Point2d getVector(cv::Point p1, cv::Point p2, int intervalCount);
bool inside(cv::Point2d point, int width, int height);
std::vector<cv::Point> point2dToLine(cv::Point2d p1, cv::Point2d p2);

std::vector<std::vector<cv::Point>> generateInnerGrid(cv::Point origin, cv::Point size, int intervalCount);

template <class T> float zCrossProduct(T a, T b, T c);
template <class T> bool isPolygonConvex(const cv::vector<T> points);
bool isPolyconConvex(const cv::vector<cv::Point> points);

#endif /* defined(__PhotoKifuCore__geometry__) */
