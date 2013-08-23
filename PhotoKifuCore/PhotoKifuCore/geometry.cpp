//
//  geometry.cpp
//  PhotoKifuCore
//
//  Created by Francois Beaussier on 30/05/13.
//  Copyright (c) 2013 Francois Beaussier. All rights reserved.
//

#include "geometry.h"
#include "MinMaxFinder.h"

double angle(const cv::Point &pt1, const cv::Point &pt2, const cv::Point &pt0)
{
    double dx1 = pt1.x - pt0.x;
    double dy1 = pt1.y - pt0.y;
    double dx2 = pt2.x - pt0.x;
    double dy2 = pt2.y - pt0.y;
    
    return (dx1 * dx2 + dy1 * dy2) / sqrt((dx1 * dx1 + dy1 * dy1) * (dx2 * dx2 + dy2 * dy2) + 1e-10);
}

double dist(const cv::Point &p1, const cv::Point &p2)
{
    int dx = p1.x - p2.x;
    int dy = p1.y - p2.y;
    
    int dst = sqrt(dx * dx + dy * dy);
    
    return dst;
}

// dist between line (a, b) and point c
/*
 double distanceBetweenLineAndPoint(const cv::Point &a, const cv::Point &b, const cv::Point &c)
{
    int top = ((c.x - a.x) * (b.x - a.x)) + ((c.y - a.y) * (b.y - a.y));
    
    int bottom = (int) (b.x - a.x) * (b.x - a.x) + (b.y - a.y) * (b.y - a.y);
    
    if (bottom == 0)
        return -1;
    
    double u = (double) top / (double) bottom;
    
    int x4 = (int) (a.x + (u * (b.x - a.x)));
    int y4 = (int) (a.y + (u * (b.y - a.y)));
    
    return sqrt((c.x - x4) * (c.x - x4) + (c.y - y4) * (c.y - y4));
}*/

double distanceBetweenLineAndPoint(const cv::Point &a, const cv::Point &b, const cv::Point &c)
{
    int x = c.x;
    int y = c.y;
    
    int x1 = a.x;
    int x2 = b.x;
    int y1 = a.y;
    int y2 = b.y;
    
    int A = x - x1;
    int B = y - y1;
    int C = x2 - x1;
    int D = y2 - y1;
    
    int dot = A * C + B * D;
    int len_sq = C * C + D * D;
    double param = dot / len_sq;
    
    int xx, yy;
    
    if (param < 0 || (x1 == x2 && y1 == y2))
    {
        xx = x1;
        yy = y1;
    }
    else if (param > 1)
    {
        xx = x2;
        yy = y2;
    }
    else
    {
        xx = x1 + param * C;
        yy = y1 + param * D;
    }
    
    int dx = x - xx;
    int dy = y - yy;

    return sqrt(dx * dx + dy * dy);
}

double distanceBetweenLines(std::vector<cv::Point> line1, std::vector<cv::Point> line2)
{
    float rho1, theta1;
    float rho2, theta2;
    
    pointsToNormalForm(line1[0], line1[1], rho1, theta1);
    pointsToNormalForm(line2[0], line2[1], rho2, theta2);
    
    float deltaRho = abs(rho1 - rho2);
    float sumRho = abs(rho1 + rho2);
//    float deltaTheta = abs(theta1 - theta2);
    
    int rhoDiff = MIN(sumRho, deltaRho);
    
//    int angleDistanceWeight = 5; // how important is the angle in the distance computation
    
//    double dist = rhoDiff + deltaTheta * angleDistanceWeight;
    
    return rhoDiff * rhoDiff;
}

void normalFormToPoint(float rho, float thetaInDeg, cv::Point &pt1, cv::Point &pt2)
{
    double res = 3000;
    
    float theta = thetaInDeg / 180 * CV_PI;
    
    double a = cos(theta), b = sin(theta);
    double x0 = a * rho, y0 = b * rho;
    
    pt1.x = cvRound(x0 + res * (-b));
    pt1.y = cvRound(y0 + res * (a));
    pt2.x = cvRound(x0 - res * (-b));
    pt2.y = cvRound(y0 - res * (a));
}

void pointsToNormalForm(const cv::Point &p1, const cv::Point &p2, float& rho, float& thetaInDeg)
{
    // convert to normal form ax + by + c = 0
    
    float a = p2.y - p1.y;
    float b = p1.x - p2.x;
    //float c = (p1.x - p2.x) * p1.y + (p2.y - p1.y) * p1.x;
    float c = (a * p1.x + b * p1.y);
    
    float dist = sqrt(a * a + b * b);
    
    if (c == 0)
    {
        c = 0;
    }
    
    //    float sign = c == 0 ? 1 : abs(c) / -c;
    float sign = -1;
    
    float distWithSign = dist * sign;
    
    float la = a / distWithSign;
    
    float lc = c / distWithSign;
    
    float theta = acosf(la);
    
    thetaInDeg = theta * 180 / CV_PI;
    
    //std::cout << "theta: " << thetaInDeg << " (" << p1.x << ", " << p1.y << " ) -> ( " << p2.x << ", " << p2.y << ") \r\n";
    
    rho = lc;
    
    // testing, reverting back to normal coordinates
    /*
     {
     double res = 1000;
     
     cv::Point pt1, pt2;
     double a = cos(theta), b = sin(theta);
     double x0 = a * rho, y0 = b * rho;
     pt1.x = cvRound(x0 + res * (-b));
     pt1.y = cvRound(y0 + res * (a));
     pt2.x = cvRound(x0 - res * (-b));
     pt2.y = cvRound(y0 - res * (a));
     
     float dy1 = p1.y - p2.y;
     float dx1 = p1.x - p2.x;
     float dy2 = pt1.y - pt2.y;
     float dx2 = pt1.x - pt2.x;
     
     float slopeLine1 = dy1 / dx1;
     float slopeLine2 = dy2 / dx2;
     
     float deltaSlope = slopeLine1 - slopeLine2;
     
     std::cout << "delta slope" << deltaSlope << "\r\n";
     }*/
    
}

bool intersection(const cv::Point &o1, const cv::Point &p1, const cv::Point &o2, const cv::Point &p2, cv::Point &r)
{
    cv::Point x = o2 - o1;
    cv::Point d1 = p1 - o1;
    cv::Point d2 = p2 - o2;
    
    float cross = d1.x * d2.y - d1.y * d2.x;
    
    if (abs(cross) < /*EPS*/1e-8)
        return false;
    
    double t1 = (x.x * d2.y - x.y * d2.x) / cross;
    
    r = o1 + d1 * t1;
    
    return true;
}

bool vertical(const std::vector<std::vector<cv::Point>> &lines)
{
    std::vector<cv::Point> firstLine = lines[0];
    
    cv::Point p1 = firstLine[0];
    cv::Point p2 = firstLine[1];
    
    int dx = abs(p1.x - p2.x);
    int dy = abs(p1.y - p2.y);
    
    return dx < dy;
}

std::vector<std::vector<cv::Point>> selectExtremeLines(int minLineLength, const std::vector<std::vector<cv::Point>> &lineSegments)
{
    std::vector<std::vector<cv::Point>> selectedLines;
    
    int minLineIndex = -1;
    int maxLineIndex = -1;
    
    if (vertical(lineSegments))
    {
        int minX = 99999;
        int maxX = 0;
        
        for (int i = 0; i < lineSegments.size(); i++)
        {
            std::vector<cv::Point> line = lineSegments[i];
            
            cv::Point p1 = line[0];
            cv::Point p2 = line[1];
            
            double norm = dist(p1, p2);
            
            if (norm > minLineLength)
            {
                if (p1.x < minX)
                {
                    minLineIndex = i;
                    minX = p1.x;
                }
                if (p2.x < minX)
                {
                    minLineIndex = i;
                    minX = p2.x;
                }
                
                if (p1.x > maxX)
                {
                    maxLineIndex = i;
                    maxX = p1.x;
                }
                if (p2.x > maxX)
                {
                    maxLineIndex = i;
                    maxX = p2.x;
                }
            }
        }
    }
    else
    {
        int minY = 99999;
        int maxY = 0;
        
        for (int i = 0; i < lineSegments.size(); i++)
        {
            std::vector<cv::Point> line = lineSegments[i];
            
            cv::Point p1 = line[0];
            cv::Point p2 = line[1];
            
            double norm = dist(p1, p2);
            
            if (norm > minLineLength)
            {
                if (p1.y < minY)
                {
                    minLineIndex = i;
                    minY = p1.y;
                }
                if (p2.y < minY)
                {
                    minLineIndex = i;
                    minY = p2.y;
                }
                
                if (p1.y > maxY)
                {
                    maxLineIndex = i;
                    maxY = p1.y;
                }
                if (p2.y > maxY)
                {
                    maxLineIndex = i;
                    maxY = p2.y;
                }
            }
        }
    }
    
    selectedLines.push_back(lineSegments[minLineIndex]);
    selectedLines.push_back(lineSegments[maxLineIndex]);
    
    if (minLineIndex == maxLineIndex)
    {
        std::cout << "Error: extreme lines are the same. This will cause issues!\r\n";
    }
    
    return selectedLines;
}
 
std::vector<cv::Point> findMinMaxPoints(const std::vector<std::vector<cv::Point>> &linesA, const std::vector<std::vector<cv::Point>> &linesB)
{
    MinMaxFinder<int> mmf;

    mmf.CheckLines(linesA);
    mmf.CheckLines(linesB);
    
    return mmf.getMinMax();
}


// Helper
template <class T>
cv::Point2f getCenter(std::vector<T> points)
{
    cv::Point2f center = T(0.0, 0.0);
    
    for (size_t i = 0; i < points.size(); i++ )
    {
        center.x += points[i].x;
        center.y += points[i].y;
    }
    
    center.x = center.x / points.size();
    center.y = center.y / points.size();
    
    return center;
}

template <class T>
bool less(T center, T a, T b)
{
    if (a.x >= 0 && b.x < 0)
        return true;
    if (a.x == 0 && b.x == 0)
        return a.y > b.y;
    
    // compute the cross product of vectors (center -> a) x (center -> b)
    int det = (a.x - center.x) * (b.y - center.y) - (b.x - center.x) * (a.y - center.y);
    
    if (det < 0)
        return true;
    
    if (det > 0)
        return false;
    
    // points a and b are on the same line from the center
    // check which point is closer to the center
    int d1 = (a.x - center.x) * (a.x - center.x) + (a.y - center.y) * (a.y - center.y);
    int d2 = (b.x - center.x) * (b.x - center.x) + (b.y - center.y) * (b.y - center.y);
    
    return d1 > d2;
}

template <class T>
struct sorterWithCenter
{
    T center;
    sorterWithCenter(T center) : center(center) { }
    
    bool operator() (T first, T second)
    {
        return less<T>(center, first, second);
    }
};

cv::vector<cv::Point> sortPoints(const cv::vector<cv::Point> points)
{
    std::vector<cv::Point> sortedPoints = points;
    
    cv::Point2f center = getCenter<cv::Point>(points);
    
    //printf("center: %2f, %2f\r\n", center.x, center.y);
    
    std::sort(sortedPoints.begin(), sortedPoints.end(), sorterWithCenter<cv::Point>(center));
    
    return sortedPoints;
}

cv::vector<cv::Point2f> sortPoints(const cv::vector<cv::Point2f> points)
{
    std::vector<cv::Point2f> sortedPoints = points;
    
    cv::Point2f center = getCenter<cv::Point2f>(points);
    
    std::sort(sortedPoints.begin(), sortedPoints.end(), sorterWithCenter<cv::Point2f>(center));
        
    return sortedPoints;
}

template <class T>
float zCrossProduct(T a, T b, T c)
{
//    return (a.x - b.x) * (c.y - b.y) - (c.x - b.x) * (a.y - b.y);
    int dx1 = b.x - a.x;
    int dy1 = b.y - a.y;
    int dx2 = c.x - b.x;
    int dy2 = c.y - b.y;
    
    return dx1 * dy2 - dy1 * dx2;
}

template <class T>
void test3PointsDirection(T a, T b, T c, int &negativeCount, int &positiveCount)
{
    int z = zCrossProduct(a, b, c);
    
    if (z > 0)
    {
        positiveCount++;
    }
    
    if (z < 0)
    {
        negativeCount++;
    }
    
    if (z == 0)
    {
        printf("isPolygonComprex: zCrossProduct is zero! returning false");
        //return false;
    }
}

template <class T>
bool isPolygonConvex(const cv::vector<T> points)
{
    if (points.size() <= 3)
        return true;
    
    int negativeCount = 0;
    int positiveCount = 0;
    
    int i = 0;
    for (; i < points.size() - 2; i++)
    {        
        test3PointsDirection<T>(points[i], points[i + 1], points[i + 2], negativeCount, positiveCount);
    }

    test3PointsDirection<T>(points[i], points[i + 1], points[0], negativeCount, positiveCount);
    test3PointsDirection<T>(points[i + 1], points[0], points[1], negativeCount, positiveCount);

    // if the z vectors are all of the same sign, it's convex
    return (positiveCount == 0 || negativeCount == 0);
}

bool isPolyconConvex(const cv::vector<cv::Point> points)
{
    return isPolygonConvex<cv::Point>(points);
}

// Helper;
// 0----1
// |    |
// |    |
// 3----2
std::vector<cv::Point2f> sortSquarePointsClockwisef(std::vector<cv::Point> square)
{
    cv::Point2f center = getCenter<cv::Point>(square);
    
    std::vector<cv::Point2f> sorted_square = std::vector<cv::Point2f>(4);

    for( size_t i = 0; i < square.size(); i++ )
    {
        int dx = square[i].x - center.x;
        int dy = square[i].y - center.y;
        
        if (dx < 0 && dy < 0)
        {
            sorted_square[0] = square[i];
        }
        else
            if (dx > 0 && dy < 0)
            {
                sorted_square[1] = square[i];
            }
            else
                if (dx > 0 && dy > 0)
                {
                    sorted_square[2] = square[i];
                }
                else
                    if (dx < 0 && dy > 0)
                    {
                        sorted_square[3] = square[i];
                    }
        
        
    }
    
    return sorted_square;
}

// Helper;
// 0----1
// |    |
// |    |
// 3----2
std::vector<cv::Point> sortSquarePointsClockwise(std::vector<cv::Point> square)
{
    cv::Point2f center = getCenter<cv::Point>(square);
    
    std::vector<cv::Point> sorted_square = std::vector<cv::Point>(4);
    
    for( size_t i = 0; i < square.size(); i++ )
    {
        int dx = square[i].x - center.x;
        int dy = square[i].y - center.y;
        
        if (dx < 0 && dy < 0)
        {
            sorted_square[0] = square[i];
        }
        else
            if (dx > 0 && dy < 0)
            {
                sorted_square[1] = square[i];
            }
            else
                if (dx > 0 && dy > 0)
                {
                    sorted_square[2] = square[i];
                }
                else
                    if (dx < 0 && dy > 0)
                    {
                        sorted_square[3] = square[i];
                    }
        
        
    }
    
    return sorted_square;
}

cv::Point2d getVector(cv::Point p1, cv::Point p2, int intervalCount)
{
    double dx = p2.x - p1.x;
    double dy = p2.y - p1.y;
    
    cv::Point2d vector(dx / intervalCount, dy / intervalCount);
    
    return vector;
}

bool inside(cv::Point2d point, int width, int height)
{
    return point.x > 0 && point.x < width && point.y > 0 && point.y < height;
}

std::vector<cv::Point> point2dToLine(cv::Point2d p1, cv::Point2d p2)
{
    std::vector<cv::Point> line;
    
    line.push_back(cv::Point(p1.x, p1.y));
    line.push_back(cv::Point(p2.x, p2.y));
    
    return line;
}

std::vector<std::vector<cv::Point>> generateInnerGrid(cv::Point origin, cv::Point size, int intervalCount)
{
    float dx = ((float) size.x) / intervalCount;
    float dy = ((float) size.y) / intervalCount;
    
    std::vector<std::vector<cv::Point>> result;

    for (int i = 1; i < intervalCount; i++)
    {
        result.push_back(point2dToLine(cv::Point(origin.x + i * dx, origin.y), cv::Point(origin.x + i * dx, origin.y + size.y)));
    }

    for (int i = 1; i < intervalCount; i++)
    {
        result.push_back(point2dToLine(cv::Point(origin.x, origin.y + i * dy), cv::Point(origin.x + size.x, origin.y + i * dy)));
    }

    return result;
}
