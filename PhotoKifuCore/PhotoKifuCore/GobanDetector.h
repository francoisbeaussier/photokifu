//
//  GobanDetector.h
//  PhotoKifu
//
//  Created by Francois Beaussier on 6/04/13.
//  Copyright (c) 2013 Francois Beaussier. All rights reserved.
//

#ifndef __PhotoKifu__GobanDetector__
#define __PhotoKifu__GobanDetector__

#include <UIKit/UIKit.h>
#include "GobanDetectorResult.h"

#define HSV_HUE         0
#define HSV_SATURATION  1
#define HSV_VALUE       2

#define BLUR_NO         0
#define BLUR_YES        1

typedef enum GobanIntersectionType
{
    GobanIntersectionTypeCorner,
    GobanIntersectionTypeTop,
    GobanIntersectionTypeRight,
    GobanIntersectionTypeBottom,
    GobanIntersectionTypeLeft,
    GobanIntersectionTypeMiddle
} GobanIntersectionType;

class GobanDetector
{

public:
 
    GobanDetector(bool debugMode);
    
    cv::vector<cv::Point> detectGoban(UIImage* image);

    GobanDetectorResult  extractGobanState(UIImage* image, cv::vector<cv::Point> contourPoints);
    
    cv::vector<std::pair<const cv::Mat, const char *>> getDebugImages();
    
private:
    
    cv::Mat VisualizeGoban(const cv::Mat &goban, const cv::Mat &bg);
    cv::Mat VisualizeGoban(const cv::vector<cv::vector<cv::Point>> stones, const cv::Mat &bg);

    bool isEmptyIntersection(const cv::Mat &imageColor, const cv::Mat &imageMono, int x, int y, GobanIntersectionType intersectionType);
    
    cv::vector<cv::vector<cv::Point>> classifyImage(cv::Mat image, cv::Mat imageMono, cv::Mat imageCanny);

    cv::vector<cv::vector<cv::Point>> testBlockAverage(cv::Mat warpedImage, cv::Mat warpedMono);

    void addDebugImage(const cv::Mat image, const char* description = NULL);

    cv::vector<cv::Point> detectGoban(cv::Mat& image);

    GobanDetectorResult extractGobanState(cv::Mat& image, cv::vector<cv::Point> contourPoints);

    cv::vector<cv::Point> detectBoard(cv::Mat& imageYuv, cv::Mat& debugDrawImage);
    bool detectGobanLines(cv::Mat& image, cv::vector<cv::Vec4i> gobanLines, cv::Mat& sourceImage);

    cv::Mat GetHSVChannel(cv::Mat &image, int channel, bool preBlur);

    cv::Mat getWarpTransform(cv::vector<cv::Point> poly);
    cv::Mat getWarpTransform2(cv::vector<cv::Point> poly, int dstWidth);
    cv::Mat getWarpTransform3(cv::Mat &image, cv::vector<cv::Point> poly);
    
    cv::Mat warpImage(cv::Mat& image, cv::Mat& transform, int dstWidth, int dstHeight);
    cv::Mat warpImage(cv::Mat& image, cv::Mat& transform, int dstWidth, int dstHeight, int dstImageFormat = CV_8UC4);
    
    cv::vector<cv::Point> extractBlackStones(cv::Mat blackStones);
    cv::vector<cv::Point> deduceWhiteStones(cv::vector<cv::Point> allStones, cv::vector<cv::Point> blackStones);

    cv::Mat extractStonePosition(cv::Mat blackStones, cv::Mat whiteStones);
    cv::Mat extractStonePosition2(cv::Mat blackStones, cv::Mat whiteStones);
    cv::vector<cv::vector<cv::Point>> extractStones(cv::Mat& goban);
    
    cv::Mat detectEdgesCanny(cv::Mat& image, int threshold);
    
    cv::Mat _greyMat;
    cv::Mat _warpedMat;
    
    bool _debugMode = false;
    cv::vector<std::pair<const cv::Mat, const char*>> _debugImages;
};

#endif /* defined(__PhotoKifu__GobanDetector__) */
