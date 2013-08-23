//
//  PerspectiveGrid.h
//  PhotoKifuCore
//
//  Created by Francois Beaussier on 18/06/13.
//  Copyright (c) 2013 Francois Beaussier. All rights reserved.
//

#ifndef __PhotoKifuCore__PerspectiveGrid__
#define __PhotoKifuCore__PerspectiveGrid__

#include <iostream>

class PerspectiveGrid
{

public:

    PerspectiveGrid();

    cv::vector<cv::vector<cv::Point>> getInnerGridLines(const cv::vector<cv::Point> &corners, int size);

    cv::vector<cv::Point> sortCorners(const cv::vector<cv::Point> &corners);
    
    bool checkPolygonIsConvex(const cv::vector<cv::Point> points);

private:
    cv::Mat getPerspectiveMatrix(const cv::vector<cv::Point> &corners, int size);

};

#endif /* defined(__PhotoKifuCore__PerspectiveGrid__) */
