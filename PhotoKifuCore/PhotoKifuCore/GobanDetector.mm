//
//  GobanDetector.cpp
//  PhotoKifu
//
//  Created by Francois Beaussier on 6/04/13.
//  Copyright (c) 2013 Francois Beaussier. All rights reserved.
//

#include "GobanDetector.h"
#include "PhotoKifuCore.h"
#include <stdlib.h>
#include "lineData.h"
#include "geometry.h"

cv::RNG rng(std::time(0));

GobanDetector::GobanDetector(bool debugMode)
    : _debugMode(debugMode)
{
}

cv::vector<std::pair<const cv::Mat, const char*>> GobanDetector::getDebugImages()
{
    return _debugImages;
}

void GobanDetector::addDebugImage(const cv::Mat image, const char* description)
{
    if (_debugMode)
    {
        std::pair<const cv::Mat, const char *> data = std::make_pair(image.clone(), description);

        _debugImages.push_back(data);
    }
}

cv::Mat scaleImage(cv::Mat& image, int scaling)
{
    cv::Mat dst = cv::Mat::zeros(image.size() * scaling, CV_8UC1);

    for (int i = 0; i < image.cols; i++)
    {
        for (int j = 0; j < image.rows; j++)
        {
            cv::Mat block = dst.rowRange(i * scaling, (i + 1) * scaling).colRange(j * scaling, (j + 1) * scaling);

            uchar value = image.at<uchar>(i, j);

            block.setTo(cv::Scalar(value));
        }
    }
    
    return dst;
}

cv::Mat GobanDetector::detectEdgesCanny(cv::Mat& image, int threshold)
{
    cv::Mat canny_output;
    
    cv::Canny(image, canny_output, threshold, threshold * 3, 3);
    
//    addDebugImage(canny_output, "Edge detection (Canny)");

    return canny_output;
}


GobanDetectorResult GobanDetector::extractGobanState(UIImage* image, cv::vector<cv::Point> contourPoints)
{
    cv::Mat img = [PhotoKifuCore cvMatFromUIImage: image];

    GobanDetectorResult result = extractGobanState(img, contourPoints);

    return result;
}

GobanDetectorResult GobanDetector::extractGobanState(cv::Mat& image, cv::vector<cv::Point> contourPoints)
{
    GobanDetectorResult result;
    
    cv::Mat debugContour = image.clone();
    
    for (int i = 0; i < 4; i++)
    {
        line(debugContour, contourPoints[i], contourPoints[(i + 1) % 4], cv::Scalar(50, 255, 0), 5, CV_AA);
    }
    
    addDebugImage(debugContour, "Goban detection");
    
    cv::Mat matV = GetHSVChannel(image, HSV_VALUE, BLUR_NO);
    
    int warpSize = 1200;
    
    cv::Mat transform = getWarpTransform2(contourPoints, warpSize);
    
    cv::Mat warpedImage = warpImage(image, transform, warpSize, warpSize, CV_8UC3);
    
    result.warpedImage = [PhotoKifuCore UIImageFromCVMat: warpedImage];
    
    cv::Mat warpedMatV = warpImage(matV, transform, warpSize, warpSize, CV_8UC1);
    
    cv::vector<cv::vector<cv::Point>> stones = testBlockAverage(warpedImage, warpedMatV);

    result.Stones = stones;
    
    return result;
}

cv::Mat GobanDetector::GetHSVChannel(cv::Mat &image, int channel, bool preBlur)
{
    cv::Mat srcHsv;

    if (preBlur)
    {
        cv::Mat blurImg;
        
        blur(image, blurImg, cv::Size(3, 3));

        cv::cvtColor(blurImg, srcHsv, CV_BGR2HSV);
}
    else
    {
        cv::cvtColor(image, srcHsv, CV_BGR2HSV);
    }
    
    cv::Mat matV;
    
    cv::vector<cv::Mat> channels;
    
    cv::split(srcHsv, channels);
    
    // channels[2] -> V -> best, default
    // channels[1] -> S -> almost as good
    // channels[0] -> H -> not great
    
    matV = channels[channel];
    
    return matV;
}

cv::vector<cv::Point> GobanDetector::detectGoban(UIImage* image)
{
    cv::Mat img = [PhotoKifuCore cvMatFromUIImage: image];
    
    return detectGoban(img);
}

cv::vector<cv::Point> GobanDetector::detectGoban(cv::Mat& image)
{
    addDebugImage(image, "Detect Goban: Source");

    cv::Mat matV = GetHSVChannel(image, HSV_VALUE, BLUR_YES);
    
    cv::vector<cv::Vec4i> lines;
    
    cv::Mat edge_output;
    
    edge_output = detectEdgesCanny(matV, 50);
    
    cv::threshold(edge_output, edge_output, 100, 255, CV_THRESH_BINARY);
    
    //    addDebugImage(edge_output, "Threshold");
    
    dilate(edge_output, edge_output, cv::Mat(), cv::Point(-1, -1), 2);
    addDebugImage(edge_output, "Dilate");
    
    erode(edge_output, edge_output, cv::Mat(), cv::Point(-1, -1), 3);
    addDebugImage(edge_output, "Erode");

    
    //detectGobanLines(edge_output, lines, image);
    
    cv::vector<cv::Point> contourPoints = detectBoard(edge_output, image);
    
    return contourPoints;
}

cv::vector<cv::Point> GobanDetector::deduceWhiteStones(cv::vector<cv::Point> allStones, cv::vector<cv::Point> blackStones)
{
    cv::vector<cv::Point> whiteStones;
    
    for (int i = 0; i < allStones.size(); i++)
    {
        bool found = false;
        
        cv::Point stone = allStones[i];
        
        for (int j = 0; j < blackStones.size(); j++)
        {
            cv::Point blackStone = blackStones[j];
            
            if (stone.x == blackStone.x && stone.y == blackStone.y)
            {
                found = true;
                
                break;
            }
        }
        
        if (!found)
        {
            whiteStones.push_back(stone);
        }
    }
    
    return whiteStones;
}

cv::vector<cv::vector<cv::Point>> GobanDetector::extractStones(cv::Mat& goban)
{
    cv::vector<cv::vector<cv::Point>> stones;
    
    cv::vector<cv::Point> blackStones;
    cv::vector<cv::Point> whiteStones;
    
    for (int i = 0; i < 19; i++)
    {
        for (int j = 0; j < 19; j++)
        {
            int stoneColor = goban.at<uchar>(i, j);
            
            if (stoneColor == 0)
            {
                blackStones.push_back(cv::Point(i, j));
            }
            else if (stoneColor == 255)
            {
                whiteStones.push_back(cv::Point(i, j));
            }
        }
    }
    
    stones.push_back(blackStones);
    stones.push_back(whiteStones);
    
    return stones;
}


int findVerticalLines(const cv::Mat &image)
{
    cv::vector<short> lineWeight(image.cols, 0);
        
    for (int x = 0; x < image.rows; x++)
    {
        for (int y = 0; y < image.cols; y++)
        {
            char pixel = image.at<char>(x, y);
            
            if (pixel != 0)
            {
                lineWeight[y]++;
            }
        }
    }

    int threshold = image.rows * 0.7;
    
    int bestFit = -1;
    
    for (int i = 0; i < lineWeight.size(); i++)
    {
        short value = lineWeight[i - 1] + lineWeight[i];
        
        if (value > threshold && value > bestFit)
        {
            bestFit = i;
        }
    }
    
    return bestFit;
}

int findHorizontalLines(const cv::Mat &image)
{
    cv::vector<short> lineWeight(image.rows, 0);
    
    for (int x = 0; x < image.rows; x++)
    {
        for (int y = 0; y < image.cols; y++)
        {
            char pixel = image.at<char>(x, y);
            
            if (pixel != 0)
            {
                lineWeight[x]++;
            }
        }
    }
    
    int threshold = image.cols * 0.7;
    
    int bestFit = -1;
    
    for (int i = 1; i < lineWeight.size(); i++)
    {
        short value = lineWeight[i - 1] + lineWeight[i];
        
        if (value > threshold && value > bestFit)
        {
            bestFit = i;
        }
    }
    
    return bestFit;
}

int counter = 0;

bool GobanDetector::isEmptyIntersection(const cv::Mat &imageColor, const cv::Mat &imageMono, int x, int y, GobanIntersectionType intersectionType)
{
    int verticalLinesIndex = findVerticalLines(imageMono);
    int horizontalLinesIndex = findHorizontalLines(imageMono);
    
    bool foundVerticalLines = verticalLinesIndex != -1;
    bool foundHorizontalLines = horizontalLinesIndex != -1;
    
    cv::Mat debugConv = imageColor.clone();
    
    if (foundVerticalLines)
    {
        line(debugConv, cv::Point(verticalLinesIndex, 0), cv::Point(verticalLinesIndex, debugConv.rows), cv::Scalar(255, 0, 255), 1, 0);
    }

    if (foundHorizontalLines)
    {
        line(debugConv, cv::Point(0, horizontalLinesIndex), cv::Point(debugConv.cols, horizontalLinesIndex), cv::Scalar(255, 0, 0), 1, 0);
    }   
    
    bool isEmptyIntersection = true;
    
    switch (intersectionType)
    {
        case GobanIntersectionTypeMiddle:
            isEmptyIntersection = foundHorizontalLines && foundVerticalLines;
            break;
            
        case GobanIntersectionTypeTop:
            isEmptyIntersection = foundHorizontalLines || foundVerticalLines;
            break;
            
        case GobanIntersectionTypeRight:
            isEmptyIntersection = foundHorizontalLines || foundVerticalLines;
            break;
            
        case GobanIntersectionTypeBottom:
            isEmptyIntersection = foundHorizontalLines || foundVerticalLines;
            break;
            
        case GobanIntersectionTypeLeft:
            isEmptyIntersection = foundHorizontalLines || foundVerticalLines;
            break;
            
        case GobanIntersectionTypeCorner:
            isEmptyIntersection = foundHorizontalLines || foundVerticalLines;
            break;

        default:
            printf("Error: unknown GobanIntersectionType: %i", intersectionType);
            
        return false;
    }
    
    bool debugImage = false;

    if (debugImage)
    {
        // Bug: remove when finished debugging as this will leak
        char *buffer = new char[255];
        
        sprintf(buffer, "Position (%i, %i) V=%i H=%i", x, y, foundVerticalLines, foundHorizontalLines);
        
        addDebugImage(imageMono, buffer);
        addDebugImage(debugConv);
    }
    
    return isEmptyIntersection;
}


GobanIntersectionType GetGobanIntersectionType(int width, int height, int x , int y)
{
    bool xMin = x == 0;
    bool xMax = x == width;
    bool yMin = y == 0;
    bool yMax = y == height;
    
    if (xMin)
    {
        if (yMin || yMax)
            return GobanIntersectionTypeCorner;
        return GobanIntersectionTypeLeft;
    }

    if (xMax)
    {
        if (yMin || yMax)
            return GobanIntersectionTypeCorner;
        return GobanIntersectionTypeRight;
    }
    
    if (yMin)
        return GobanIntersectionTypeTop;
    if (yMax)
        return GobanIntersectionTypeBottom;
    
    return GobanIntersectionTypeMiddle;
    
// x==00  x==18  y==00  y==19  result
// -----  -----  -----  -----  ------
//   0      0      0      0    middle

//   0      0      0      1    bottom
//   0      0      1      0    top
//   0      1      0      0    right
//   1      0      0      0    left

//   0      1      0      1    corner
//   0      1      1      0    corner
//   1      0      0      1    corner
//   1      0      1      0    corner  

}

cv::vector<cv::vector<cv::Point>> GobanDetector::classifyImage(cv::Mat image, cv::Mat imageMono, cv::Mat imageCanny)
{
    int width = 1200;
    int height = 1200;
    
    assert(image.cols == width);
    assert(image.rows == height);
    
    int histBuckets = 256;
    int hist[histBuckets];

    memset(&hist, 0, sizeof(int) * histBuckets);

    float dx = image.cols / 18.0;
    float dy = image.rows / 18.0;
    
    float ratio = 3.0f;
    
    int x1 = dx / ratio;
    int y1 = dy / ratio;

    cv::Mat goban(19, 19, CV_8UC1, cv::Scalar(0));
    
    cv::Mat result = cv::Mat(image.cols, image.rows, CV_8UC1, cv::Scalar(255));

    for (int i = 0; i < 19; i++)
    {
        for (int j = 0; j < 19; j++)
        {
            int xMin = MAX(0, dx * i - x1);
            int xMax = MIN(image.cols - 1, dx * i - 1 + x1);
            
            int yMin = MAX(0, dy * j - y1);
            int yMax = MIN(image.rows - 1, dy * j - 1 + y1);
            
            cv::Mat block = image.rowRange(xMin, xMax).colRange(yMin, yMax);
            cv::Mat blockCanny = imageCanny.rowRange(xMin, xMax).colRange(yMin, yMax);

            GobanIntersectionType intersectionType = GetGobanIntersectionType(18, 18, i, j);
            
            bool containsStone = !isEmptyIntersection(block, blockCanny, i, j, intersectionType);
            
            goban.at<char>(i, j) = containsStone ? 1 : 0;
            
            if (containsStone)
            {
                cv::Scalar mean = cv::mean(block);
                
                //0.2126 * R + 0.7152 * G + 0.0722 * B
                
                //int meanNormalized = (0.0722 * mean[0] + 0.7152 * mean[1] + 0.2126 * mean[2]);
                int meanNormalized = (mean[0] + mean[1] + mean[2]) / 3;
                
                hist[meanNormalized]++;
            }
        }
    }

    VisualizeGoban(goban, image);
    
    cv::Mat blackOnly;
    
    
    cv::threshold(imageMono, blackOnly, 50, 255, CV_THRESH_BINARY);
    
    dilate(blackOnly, blackOnly, cv::Mat(), cv::Point(-1, -1), 1);
    erode(blackOnly, blackOnly, cv::Mat(), cv::Point(-1, -1), 1);
    
    cv::bitwise_not(blackOnly, blackOnly);
    
//    addDebugImage(blackOnly, "Dilate, erode and inverse colors");

    cv::vector<cv::Point> allStones;
    
    for (int x = 0; x < goban.cols; x++)
    {
        for (int y = 0; y < goban.rows; y++)
        {
            char clusterIndex = goban.at<char>(x, y);
            
            if (clusterIndex != 0)
            {
                allStones.push_back(cv::Point(y, x));
            }
        }
    }

    
    cv::vector<cv::Point> blackStones = extractBlackStones(blackOnly);
    
    cv::vector<cv::Point> whiteStones = deduceWhiteStones(allStones, blackStones);
    
    
    cv::vector<cv::vector<cv::Point>> stones;
    
    stones.push_back(blackStones);
    stones.push_back(whiteStones);
    
    
    VisualizeGoban(stones, image);

    return stones;
}

cv::vector<cv::vector<cv::Point>> GobanDetector::testBlockAverage(cv::Mat warpedImage, cv::Mat warpedMono)
{
    cv::Mat warpedCanny = detectEdgesCanny(warpedMono, 40);
    
//    addDebugImage(warpedCanny, "Warped Canny");
    
    cv::vector<cv::vector<cv::Point>> stones = classifyImage(warpedImage, warpedMono, warpedCanny);

    return stones;
}

cv::Mat GobanDetector::VisualizeGoban(const cv::Mat &goban, const cv::Mat &bg)
{
    float w = bg.cols / 18.0f;
    
    cv::Mat clusterVisualisation = bg.clone();
    cv::Mat overlay;
    
    clusterVisualisation.copyTo(overlay);
    
    for (int x = 0; x < goban.cols; x++)
    {
        for (int y = 0; y < goban.rows; y++)
        {
            int x1 = w / 2;
            int y1 = w / 2;
            
            int xMin = MAX(0, w * x - x1);
            int xMax = MIN(clusterVisualisation.cols - 1, w * x - 1 + x1);
            
            int yMin = MAX(0, w * y - y1);
            int yMax = MIN(clusterVisualisation.rows - 1, w * y - 1 + y1);

            if (x == 18)
            {
                int ii = 1;
                ii++;
            }
            
            cv::line(overlay, cv::Point(w * x, w * y), cv::Point(w * x, w * y), cv::Scalar(0, 0, 255), 3);

            cv::Mat block = overlay.rowRange(xMin, xMax).colRange(yMin, yMax);
            
            char clusterIndex = goban.at<char>(x, y);
            
            if (clusterIndex == 1)
            {
                block.setTo(cv::Scalar(255, 0, 0));
            }
        }
    }
    
    double opacity = 0.4;
    cv::addWeighted(overlay, opacity, clusterVisualisation, 1 - opacity, 0, clusterVisualisation);
    
    addDebugImage(clusterVisualisation, "Cluster Visualisation");

    return clusterVisualisation;
}

cv::Mat GobanDetector::VisualizeGoban(const cv::vector<cv::vector<cv::Point>> stones, const cv::Mat &bg)
{
    float w = bg.cols / 18.0f;
    
    //    cv::Mat clusterVisualisation = cv::Mat(goban.rows * w, goban.cols * w, CV_8UC1);
    cv::Mat clusterVisualisation = bg.clone();
    cv::Mat overlay;
    
    clusterVisualisation.copyTo(overlay);
    
    cv::vector<cv::Point> whiteStones = stones[0];
    cv::vector<cv::Point> blackStones = stones[1];
    
    for (int i = 0; i < whiteStones.size(); i++)
    {
        cv::Point whiteStone = whiteStones[i];
        
        int x = whiteStone.y;
        int y = whiteStone.x;
        
        int x1 = w / 2;
        int y1 = w / 2;
        
        int xMin = MAX(0, w * x - x1);
        int xMax = MIN(clusterVisualisation.cols - 1, w * x - 1 + x1);
        
        int yMin = MAX(0, w * y - y1);
        int yMax = MIN(clusterVisualisation.rows - 1, w * y - 1 + y1);
        
        cv::Mat block = overlay.rowRange(xMin, xMax).colRange(yMin, yMax);
        
        block.setTo(cv::Scalar(255, 0, 0));
        
        circle(overlay, cv::Point(w * y, w * x), 10, cv::Scalar(0, 255, 0), 5);
    }

    for (int i = 0; i < blackStones.size(); i++)
    {
        cv::Point blackStone = blackStones[i];
        
        int x = blackStone.y;
        int y = blackStone.x;
        
        int x1 = w / 2;
        int y1 = w / 2;
        
        int xMin = MAX(0, w * x - x1);
        int xMax = MIN(clusterVisualisation.cols - 1, w * x - 1 + x1);
        
        int yMin = MAX(0, w * y - y1);
        int yMax = MIN(clusterVisualisation.rows - 1, w * y - 1 + y1);
        
        cv::Mat block = overlay.rowRange(xMin, xMax).colRange(yMin, yMax);
        
        block.setTo(cv::Scalar(0, 255, 0));

        circle(overlay, cv::Point(w * y, w * x), 10, cv::Scalar(255, 0, 0), 5);
    }
    
    double opacity = 0.4;
    cv::addWeighted(overlay, opacity, clusterVisualisation, 1 - opacity, 0, clusterVisualisation);
    
    addDebugImage(clusterVisualisation, "Cluster Visualisation");
    
    return clusterVisualisation;
}

cv::vector<cv::Point> GobanDetector::extractBlackStones(cv::Mat blackStones)
{
    cv::vector<cv::Point> result;
    
    for (int i = 0; i < 19; i++)
    {
        for (int j = 0; j < 19; j++)
        {
            float dx = blackStones.cols / 18.0;
            float dy = blackStones.rows / 18.0;
            
            int x1 = -dx / 2;
            int y1 = -dy / 2;
            
            int xMin = MAX(0, x1 + dx * i);
            int xMax = MIN(blackStones.cols - 1, x1 + dx * (i + 1) - 1);
            
            int yMin = MAX(0, y1 + dy * j);
            int yMax = MIN(blackStones.rows - 1, y1 + dy * (j + 1) - 1);
            
            cv::Mat block = blackStones.rowRange(xMin, xMax).colRange(yMin, yMax);
            
            cv::Scalar mean = cv::mean(block);
            
            if (mean[0] > 50)
            {
//                goban.at<uchar>(j, i) = 0;
                result.push_back(cv::Point(j, i));
            }
        }
    }
    
    return result;
}
/*
cv::Mat GobanDetector::extractStonePosition(cv::Mat blackStones, cv::Mat whiteStones)
{
    cv::Mat goban = cv::Mat::zeros(19, 19, CV_8UC1);
    
    goban.setTo(cv::Scalar(128, 128, 128));

    for (int i = 0; i < 19; i++)
    {
        for (int j = 0; j < 19; j++)
        {
            float dx = blackStones.cols / 18.0;
            float dy = blackStones.rows / 18.0;
            
            int x1 = -dx / 2;
            int y1 = -dy / 2;
            
            int xMin = MAX(0, x1 + dx * i);
            int xMax = MIN(blackStones.cols - 1, x1 + dx * (i + 1) - 1);

            int yMin = MAX(0, y1 + dy * j);
            int yMax = MIN(blackStones.rows - 1, y1 + dy * (j + 1) - 1);
            
            cv::Mat block = blackStones.rowRange(xMin, xMax).colRange(yMin, yMax);
            
            cv::Scalar mean = cv::mean(block);
            
            if (mean[0] > 50)
            {
                goban.at<uchar>(j, i) = 0;
            }
            else
            {
                block = whiteStones.rowRange(xMin, xMax).colRange(yMin, yMax);
                
                mean = cv::mean(block);
                
                if (mean[0] > 50)
                {
                    goban.at<uchar>(j, i) = 255;
                }
            }

            // debug
            rectangle(blackStones, cv::Point(xMin, yMin), cv::Point(xMax, yMax), cv::Scalar(100));
            rectangle(whiteStones, cv::Point(xMin, yMin), cv::Point(xMax, yMax), cv::Scalar(100));
        }
    }
    
    addDebugImage(blackStones, "Black stones detection (the grid position is arbitrary, work in progress)");
    addDebugImage(whiteStones, "White stones detection (the grid position is arbitrary, work in progress)");

    return goban;
}*/

cv::Mat GobanDetector::warpImage(cv::Mat& image, cv::Mat& transform, int dstWidth, int dstHeight, int dstImageFormat)
{
    // Define the destination image
    cv::Mat quad = cv::Mat::zeros(dstWidth, dstHeight, dstImageFormat);
        
    // Apply perspective transformation
    cv::warpPerspective(image, quad, transform, quad.size());
    
    return quad;
}

cv::Mat GobanDetector::getWarpTransform(cv::vector<cv::Point> poly)
{
    std::vector<cv::Point2f> corners = sortSquarePointsClockwisef(poly);

    int averageWidth = cv::norm(corners[0] - corners[1]) + cv::norm(corners[2] - corners[3]);
    int averageHeight = cv::norm(corners[1] - corners[2]) + cv::norm(corners[3] - corners[0]);
    
    // Corners of the destination image
    std::vector<cv::Point2f> quad_pts;

    int dx = 800;
    int dy = 800;
    
    averageWidth /= 5;
    averageHeight /= 5;
    
    quad_pts.push_back(cv::Point2f(dx, dy));
    quad_pts.push_back(cv::Point2f(dx + averageWidth, dy));
    quad_pts.push_back(cv::Point2f(dx + averageWidth, dy + averageHeight));
    quad_pts.push_back(cv::Point2f(dx, dy + averageHeight));
    
    // Get transformation matrix
    cv::Mat transmtx = cv::getPerspectiveTransform(corners, quad_pts);
//    cv::Mat transmtx = cv::getAffineTransform(corners, quad_pts);
    
    return transmtx;
}

cv::Mat GobanDetector::getWarpTransform3(cv::Mat &image, cv::vector<cv::Point> poly)
{
    std::vector<cv::Point2f> corners = sortSquarePointsClockwisef(poly);
    
    int width = MAX(cv::norm(corners[0] - corners[1]), cv::norm(corners[2] - corners[3]));
    int height = MAX(cv::norm(corners[1] - corners[2]), cv::norm(corners[3] - corners[0]));
    
    // Corners of the destination image
    std::vector<cv::Point2f> quad_pts;
    
    int dx = image.cols / 5;
    int dy = image.rows / 5;
    
    quad_pts.push_back(cv::Point2f(dx, dy));
    quad_pts.push_back(cv::Point2f(dx + width, dy));
    quad_pts.push_back(cv::Point2f(dx + width, dy + height));
    quad_pts.push_back(cv::Point2f(dx, dy + height));
    
    // Get transformation matrix
    cv::Mat transmtx = cv::getPerspectiveTransform(corners, quad_pts);
    //    cv::Mat transmtx = cv::getAffineTransform(corners, quad_pts);
    
    return transmtx;
}

cv::Mat GobanDetector::getWarpTransform2(cv::vector<cv::Point> poly, int dstWidth)
{
    std::vector<cv::Point2f> corners = sortSquarePointsClockwisef(poly);
    
    printf("corner 0: (%f, %f)\r\n", corners[0].x, corners[0].y);
    printf("corner 1: (%f, %f)\r\n", corners[1].x, corners[1].y);
    printf("corner 2: (%f, %f)\r\n", corners[2].x, corners[2].y);
    printf("corner 3: (%f, %f)\r\n", corners[3].x, corners[3].y);
    
    // Corners of the destination image
    std::vector<cv::Point2f> quad_pts;
        
    quad_pts.push_back(cv::Point2f(0, 0));
    quad_pts.push_back(cv::Point2f(dstWidth, 0));
    quad_pts.push_back(cv::Point2f(dstWidth, dstWidth));
    quad_pts.push_back(cv::Point2f(0, dstWidth));
    
    
    // Get transformation matrix
    cv::Mat transmtx = cv::getPerspectiveTransform(corners, quad_pts);
    
    return transmtx;
}

cv::vector<cv::Point> GobanDetector::detectBoard(cv::Mat& image, cv::Mat& debugDrawImage)
{
    cv::vector<cv::vector<cv::Point>> contours;
    cv::vector<cv::Vec4i> hierarchy;
    
    cv::Mat imageContour = image.clone(); // findContours does modify the image
    
    cv::findContours(imageContour, contours, hierarchy, CV_RETR_LIST, CV_CHAIN_APPROX_SIMPLE);
    //cv::findContours(imageContour, contours, hierarchy, CV_RETR_EXTERNAL, CV_CHAIN_APPROX_SIMPLE);
    
    cv::vector<cv::vector<cv::Point>> contours_poly(contours.size());
    
    int contourCount = contours.size();
        
    int largestPolyIndex = -1;
    double largestPolyArea = -1;
    
    int polyDrawnDebug = 0;
    
    cv::Mat debugAllContours = debugDrawImage.clone();
    cv::Mat debugAllQuadConvecContours = debugDrawImage.clone();

    for (int i = 0; i < contourCount; i++)
    {
        cv::vector<cv::Point> hull;
        cv::convexHull(contours[i], hull);
        
        cv::Mat hullMat = cv::Mat(hull);
        approxPolyDP(hullMat, contours_poly[i], arcLength(hullMat, true) * 0.02, true);
        //approxPolyDP(cv::Mat(contours[i]), contours_poly[i], arcLength(cv::Mat(contours[i]), true) * 0.02, true);
        
        double area = fabs(contourArea(cv::Mat(contours_poly[i])));
        
        if (area > 10000)
        {
            cv::drawContours(debugAllContours, contours, i, cv::Scalar((13 *  i) % 255, (131 *  i) % 255, (1313 *  i) % 255), 5, 8);
        }
        
        if (contours_poly[i].size() > 3 && contours_poly[i].size() < 6 &&
             area > 10000
            //&& isContourConvex(cv::Mat(contours_poly[i]))
            )
        {
            double maxCosine = 0;
            
            for( int j = 2; j < 5; j++ )
            {
                cv::Point pt0 = contours_poly[i][j-1];
                
                double cosine = fabs(angle(contours_poly[i][j%4], contours_poly[i][j-2], pt0));
                maxCosine = MAX(maxCosine, cosine);
            }
            
            cv::drawContours(debugAllQuadConvecContours, contours, i, cv::Scalar((13 *  i) % 255, (131 *  i) % 255, (1313 *  i) % 255), 5, 8);

            //if (maxCosine < 0.7)
            {
                if (area > largestPolyArea)
                {
                    //cv::Point p0 = contours_poly[i][0];
                    
                    /*
                    for (int j = 0; j < 4; j++)
                    {
                        cv::line(debugDrawImage, contours_poly[i][j], contours_poly[i][j + 1], cv::Scalar(50, 255, 0), 5, CV_AA);
                    }
                    */
                    
                    largestPolyArea = area;
                    largestPolyIndex = i;
                }
                
                //                int size = contours_poly[i].size();
                
                //                return &(contours_poly[i]);
            }
            
        }
    }
    
    addDebugImage(debugAllContours, "All contours");
    
    cv::drawContours(debugAllQuadConvecContours, contours, largestPolyIndex, cv::Scalar(0, 255, 0), 5, 8);

    addDebugImage(debugAllQuadConvecContours, "Quad and convex contours");

    polyDrawnDebug++;

    
    if (largestPolyIndex == -1)
    {
        return cv::vector<cv::Point>();
    }
    
    cv::Mat largestContour = debugDrawImage.clone();
    
    cv::drawContours(largestContour, contours, largestPolyIndex, cv::Scalar(0, 255, 0), 5, 8);

    addDebugImage(largestContour);
    
    cv::vector<cv::Point> contourPoints = cv::vector<cv::Point>(contours_poly[largestPolyIndex]);
    
    cv::Mat debugContour = debugDrawImage.clone();
    
    for (int i = 0; i < 4; i++)
    {
        line(debugContour, contourPoints[i], contourPoints[(i + 1) % 4], cv::Scalar(50, 255, 0), 5, CV_AA);
    }
    
    addDebugImage(debugContour, "Goban detection");
    
    return contourPoints;
}
