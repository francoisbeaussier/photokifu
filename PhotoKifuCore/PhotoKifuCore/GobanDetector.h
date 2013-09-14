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

    cv::vector<cv::vector<cv::Point>> extractGobanState(UIImage* image, cv::vector<cv::Point> contourPoints);
    
    cv::vector<std::pair<const cv::Mat, const char *>> getDebugImages();
    
private:
    
    cv::Mat VisualizeGoban(const cv::Mat &goban, const cv::Mat &bg);

    bool isEmptyIntersection(const cv::Mat &imageColor, const cv::Mat &imageMono, int x, int y, GobanIntersectionType intersectionType);
    
    cv::Mat classifyImage(cv::Mat image, cv::Mat imageMone);
    cv::vector<double> findClusters(const cv::Mat& data, int clusterCount);
    void findKMeans(const cv::Mat& data, int gridAverages[], int clusterCount);

    cv::Mat createHistogram(int histValues[], int histBuckets, cv::Scalar color, const char *histTitle);

    void testBlockAverage(cv::Mat warpedImage, cv::Mat warpedMono);

    void addDebugImage(const cv::Mat image, const char* description = NULL);

    std::vector<cv::Point> detectGobanCorners(cv::Mat &image, std::vector<std::vector<cv::Point>> lineSegmentsClusters1, std::vector<std::vector<cv::Point>> lineSegmentsClusters2);

    cv::vector<cv::Point> detectGoban(cv::Mat& image);

    cv::vector<cv::vector<cv::Point>> extractGobanState(cv::Mat& image, cv::vector<cv::Point> contourPoints);

    cv::vector<cv::Point> detectBoard(cv::Mat& imageYuv, cv::Mat& debugDrawImage);
    bool detectGobanLines(cv::Mat& image, cv::vector<cv::Vec4i> gobanLines, cv::Mat& sourceImage);

    cv::Mat GetHSVChannel(cv::Mat &image, int channel, bool preBlur);

    void surfDetection(cv::Mat& image);

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

    void customBlackAndWhite(cv::Mat& image);

    
    std::vector<cv::Point> getIntersections(std::vector<std::vector<cv::Point>> lines1, std::vector<std::vector<cv::Point>> lines2);
    std::vector<cv::Point> getIntersections(int minLineLength, int minDistanceBetweenLines, std::vector<std::vector<std::vector<cv::Point>>> lineSegmentsClusters);
    std::vector<cv::Point> getLargestIntersections(int minLineLength, std::vector<std::vector<std::vector<cv::Point>>> lineSegmentsClusters);
    
    std::vector<std::vector<cv::Point>> selectLines(int minLineLength, int minDistanceBetweenLines, std::vector<std::vector<cv::Point>> lineSegments);
//    std::vector<std::vector<cv::Point>> selectExtremeLines(int minLineLength, std::vector<std::vector<cv::Point>> lineSegments);

    bool detectPlanarHomography(cv::Mat& image, cv::Point vanishingPoint1, cv::Point vanishingPoint2);

    cv::Point linePassingByPoint(cv::Point a, cv::Point b, cv::Point passingBy);
//    double distanceBetweenLineAndPoint(cv::Point a, cv::Point b, cv::Point c);
    cv::Point closestLinePassingByPoint(cv::vector<cv::Point> l1, cv::vector<cv::Point> l2, cv::Point passingBy);

    cv::Mat detectEdgesCanny(cv::Mat& image, int threshold);
    cv::Mat detectEdgesLaplacian(cv::Mat& image);

    void detectHarrisCorners(cv::Mat& src);

    void testLines();

    bool intersectionWithEdge(cv::vector<cv::Point> a, cv::vector<cv::Point> b, cv::vector<cv::Point> a2, cv::vector<cv::Point> b2, cv::Rect edges, std::vector<cv::Point> &corners);
    
    cv::Mat _greyMat;
    cv::Mat _warpedMat;
    
    bool _debugMode = false;
    cv::vector<std::pair<const cv::Mat, const char*>> _debugImages;
};

#endif /* defined(__PhotoKifu__GobanDetector__) */
