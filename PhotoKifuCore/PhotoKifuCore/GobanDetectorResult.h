//
//  GobanDetectResult.h
//  PhotoKifuCore
//
//  Created by Francois Beaussier on 22/12/2013.
//  Copyright (c) 2013 Francois Beaussier. All rights reserved.
//

#ifndef __PhotoKifuCore__GobanDetectResult__
#define __PhotoKifuCore__GobanDetectResult__

#include <UIKit/UIKit.h>

class GobanDetectorResult
{
    
public:
    
    GobanDetectorResult();
    
    cv::vector<cv::vector<cv::Point>> Stones;

    UIImage * warpedImage;
};

#endif /* defined(__PhotoKifuCore__GobanDetectResult__) */
