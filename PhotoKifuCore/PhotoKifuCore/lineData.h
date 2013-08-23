//
//  lineData.h
//  PhotoKifuCore
//
//  Created by Francois Beaussier on 9/05/13.
//  Copyright (c) 2013 Francois Beaussier. All rights reserved.
//

#ifndef __PhotoKifuCore__lineData__
#define __PhotoKifuCore__lineData__

#include <iostream>

class lineData
{
public:
    
    cv::Point pt1, pt2;
    float rho;
    float theta;
    float norm;
    bool retain;
};

#endif /* defined(__PhotoKifuCore__lineData__) */
