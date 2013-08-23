//
//  GeometryTests.cpp
//  PhotoKifuCore
//
//  Created by Francois Beaussier on 30/05/13.
//  Copyright (c) 2013 Francois Beaussier. All rights reserved.
//

#include "GeometryTests.h"
#include "geometry.h"

@implementation GeometryTests

- (void) testSortingStrangeCase
{
    cv::vector<cv::Point> points;
    
    points.push_back(cv::Point(2030, 977));
    points.push_back(cv::Point(1581, 1377));
    points.push_back(cv::Point(1174, 799));
    points.push_back(cv::Point(847, 1175));

    cv::vector<cv::Point> sortedPoints = sortPoints(points);
    
    for (int i = 0; i < sortedPoints.size(); i++)
    {
        printf("%i, %i\r\n", sortedPoints[i].x, sortedPoints[i].y);
    }
    
}

@end