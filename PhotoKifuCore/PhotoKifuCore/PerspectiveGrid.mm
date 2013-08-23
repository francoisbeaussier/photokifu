//
//  PerspectiveGrid.cpp
//  PhotoKifuCore
//
//  Created by Francois Beaussier on 18/06/13.
//  Copyright (c) 2013 Francois Beaussier. All rights reserved.
//

#include "PerspectiveGrid.h"
#include "geometry.h"

PerspectiveGrid::PerspectiveGrid()
{
    
}

cv::vector<cv::vector<cv::Point>> PerspectiveGrid::getInnerGridLines(const cv::vector<cv::Point> &corners, int size)
{
    cv::Mat m = getPerspectiveMatrix(corners, 1000);
    
    cv::Mat invTransform = m.inv();
    
    cv::vector<cv::vector<cv::Point>> gridLines = generateInnerGrid(cv::Point(0, 0), cv::Point(1000, 1000), size - 1);
    
    std::vector<cv::Point2f> gridLines2f;
    
    for (int i = 0; i < gridLines.size(); i++)
    {
        cv::vector<cv::Point> l = gridLines[i];
        gridLines2f.push_back(cv::Point2f(l[0].x, l[0].y));
        gridLines2f.push_back(cv::Point2f(l[1].x, l[1].y));
    }
    
    std::vector<cv::Point2f> invGridLines(gridLines2f.size());
    
    perspectiveTransform(gridLines2f, invGridLines, invTransform);
    
    cv::vector<cv::vector<cv::Point>> lines;
    
    for (int i = 0; i < invGridLines.size(); i += 2)
    {
        cv::Point a = cv::Point(invGridLines[i].x, invGridLines[i].y);
        cv::Point b = cv::Point(invGridLines[i + 1].x, invGridLines[i + 1].y);
        cv::vector<cv::Point> line;
        
        line.push_back(a);
        line.push_back(b);
        
        lines.push_back(line);
    }

    return lines;
}


cv::Mat PerspectiveGrid::getPerspectiveMatrix(const cv::vector<cv::Point> &corners, int size)
{
    cv::vector<cv::Point2f> corners2f;

    for (int i = 0; i < corners.size(); i++)
    {
        cv::Point p = corners[i];
        corners2f.push_back(cv::Point2f(p.x, p.y));
    }
    
    std::vector<cv::Point2f> sortedCorners2f = sortPoints(corners2f);
    
    // Corners of the destination image
    std::vector<cv::Point2f> quad_pts;
    
    quad_pts.push_back(cv::Point2f(0, 0));
    quad_pts.push_back(cv::Point2f(size, 0));
    quad_pts.push_back(cv::Point2f(size, size));
    quad_pts.push_back(cv::Point2f(0, size));
    
    cv::Mat transmtx = cv::getPerspectiveTransform(sortedCorners2f, quad_pts);
        
    return transmtx;
}

cv::vector<cv::Point> PerspectiveGrid::sortCorners(const cv::vector<cv::Point> &corners)
{
    std::vector<cv::Point> sortedPoints = sortPoints(corners);
    
    return sortedPoints;
}

bool PerspectiveGrid::checkPolygonIsConvex(const cv::vector<cv::Point> points)
{
    return isPolygonConvex(points);
}

