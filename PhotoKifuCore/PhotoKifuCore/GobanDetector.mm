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
#include "opencv2/features2d/features2d.hpp"
#include "opencv2/nonfree/features2d.hpp" //This is where actual SURF and SIFT algorithm is located
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

cv::Mat GobanDetector::detectEdgesLaplacian(cv::Mat& image)
{
    medianBlur(image, image, 3);
    
    cv::Mat dst, abs_dst;
    
    cv::Laplacian(image, dst, CV_16S, 3, 1, 0, cv::BORDER_DEFAULT);
    
//    addDebugImage(dst);

    cv::convertScaleAbs(dst, abs_dst);

//    addDebugImage(abs_dst);

    return abs_dst;
}

void GobanDetector::customBlackAndWhite(cv::Mat& image)
{
    for (int row = 0; row < image.rows; ++row)
    {
        uchar* p = image.ptr(row);
        
        for (int col = 0; col < image.cols; ++col)
        {
            int b = p[0];
            int g = p[1];
            int r = p[2];
            
            int avg = (b + r + g) / 3;
            
            int db = abs(avg - b);
            int dg = abs(avg - g);
            int dr = abs(avg - r);
            
            int dMax = MAX(db, MAX(dg, dr));
            
            int cMax = MAX(b, MAX(g, r));
            
            //int dist = (sqrt(r + g + b + dMax * dMax));
            //int dist = cMax; //sqrt(cMax * cMax);
            int dist = cMax + dMax;// + dMax;
            
            uchar bw = MIN(dist, 255);
            
            p[0] = p[1] = p[2] = p[3] = bw;
            /*
            int db = abs(p[1] - p[0]);
            int dr = abs(p[1] - p[2]);
            
            int dst = sqrt(db * db + dr * dr);
            
            if (p[0] < 50 && p[1] < 50 && p[2] < 50)
            {
                dst = 255;
            }
            
            p[0] = p[1] = p[2] = p[3] = p[0] & p[1] & p[2];
            */
            
            p += 4;
        }
    }
    
    addDebugImage(image, "custom Black and White ");
}

void GobanDetector::surfDetection(cv::Mat& image)
{
    cv::Mat imgBRG;
    
//    cv::cvtColor(image, imgBRG, CV_GRAY2BGR);
    imgBRG = image.clone();

    cv::Mat imgBRG2 = imgBRG.clone();
    
    cv::Scalar white(255, 255, 255);
    cv::Scalar black(0, 0, 0);

    cv::Scalar lineColor = white;
    cv::Scalar backColor = black;
    
    int margin = 100;
    int squareCount = 18;
    int squareWidth = 25;
    int width = margin + squareCount * (squareWidth + 1) + margin;
    cv::Mat goban = cv::Mat(cv::Point(width, width), CV_8UC3, backColor);
    
    for (int i = 0; i < squareCount + 1; i++)
    {
        cv::Point pt1(margin + i * (squareWidth + 1), margin);
        cv::Point pt2(margin + i * (squareWidth + 1), margin + squareCount * (squareWidth + 1));
        
        line(goban, pt1, pt2, lineColor, 1);
        
        cv::Point pt3(margin, margin + i * (squareWidth + 1));
        cv::Point pt4(margin + squareCount * (squareWidth + 1), margin + i * (squareWidth + 1));
        
        line(goban, pt3, pt4, lineColor, 1);
    }
    
    addDebugImage(goban);
    
    
    cv::vector<cv::KeyPoint> keypointsO;
    cv::vector<cv::KeyPoint> keypointsI;
    
    cv::Mat descriptors_object, descriptors_image;
    
    cv::SiftFeatureDetector surf;
    surf.detect(goban, keypointsO);

    cv::SiftFeatureDetector surf2;
    surf2.detect(image, keypointsI);
    
    drawKeypoints(goban, keypointsO, goban, cv::Scalar(0, 0, 255), cv::DrawMatchesFlags::DRAW_RICH_KEYPOINTS);
    drawKeypoints(image, keypointsI, imgBRG, cv::Scalar(0, 255, 0), cv::DrawMatchesFlags::DRAW_RICH_KEYPOINTS);

    
    
    //printf("-- Keypoints goban : %li \n", keypointsO.size());
    //printf("-- Keypoints image : %li \n", keypointsI.size());

    addDebugImage(goban);
    addDebugImage(imgBRG);
    
    cv::SiftDescriptorExtractor extractor;
    extractor.compute(image, keypointsI, descriptors_image);
    extractor.compute(goban, keypointsO, descriptors_object);
    
     cv::FlannBasedMatcher matcher;
     
     cv::vector<cv::vector<cv::DMatch>> matches;
     matcher.knnMatch( descriptors_object, descriptors_image, matches, 2); // find the 2 nearest neighbors

     cv::vector<cv::DMatch> good_matches;
    good_matches.reserve(matches.size());
    
    float nndrRatio = 0.9f;
    
    for (size_t i = 0; i < matches.size(); ++i)
    {
        if (matches[i].size() < 2)
            continue;
        
        const cv::DMatch &m1 = matches[i][0];
        const cv::DMatch &m2 = matches[i][1];
        
        if (m1.distance <= nndrRatio * m2.distance)
            good_matches.push_back(m1);
    }
    
    /*
    
    double max_dist = 0; double min_dist = 100;
    
    //-- Quick calculation of max and min distances between keypoints
    for( int i = 0; i < descriptors_object.rows; i++ )
    {
        double dist = matches[i].distance;
        if( dist < min_dist ) min_dist = dist;
        if( dist > max_dist ) max_dist = dist;
    }
    
    printf("-- Max dist : %f \n", max_dist );
    printf("-- Min dist : %f \n", min_dist );
    
    //-- Draw only "good" matches (i.e. whose distance is less than 3*min_dist )
    std::vector<cv::DMatch > good_matches;
    
    for( int i = 0; i < descriptors_object.rows; i++ )
    {
        if( matches[i].distance < 3 * min_dist )
        {
            good_matches.push_back( matches[i]);
        }
    }*/
    
    cv::Mat imgMatches = imgBRG.clone();

    cv::Mat img_matches;
    drawMatches( goban, keypointsO, imgBRG2, keypointsI, good_matches, img_matches, cv::Scalar::all(-1), cv::Scalar::all(-1),
                cv::vector<char>(), cv::DrawMatchesFlags::NOT_DRAW_SINGLE_POINTS );
    
//    addDebugImage(imgBRG2);
    addDebugImage(img_matches);
    
    // return;
    
    std::vector<cv::Point2f> obj;
    std::vector<cv::Point2f> scene;
    
    for( unsigned int i = 0; i < good_matches.size(); i++ )
    {
        //-- Get the keypoints from the good matches
        obj.push_back(keypointsO[good_matches[i].queryIdx].pt);
        scene.push_back(keypointsI[good_matches[i].trainIdx].pt);
    }
    
    cv::Mat H = findHomography(obj, scene, CV_RANSAC);
    
    //-- Get the corners from the image_1 ( the object to be "detected" )
    std::vector<cv::Point2f> obj_corners(4);
    obj_corners[0] = cvPoint(0, 0);
    obj_corners[1] = cvPoint(goban.cols, 0);
    obj_corners[2] = cvPoint(goban.cols, goban.rows);
    obj_corners[3] = cvPoint(0, goban.rows);
    std::vector<cv::Point2f> scene_corners(4);
    
    perspectiveTransform(obj_corners, scene_corners, H);
    
    cv::Scalar color = cv::Scalar(0, 0, 255);
    
    //-- Draw lines between the corners (the mapped object in the scene - image_2 )
    line( imgBRG2, cv::Point(0, 0), scene_corners[0], color, 20); //TOP line

    line( imgBRG2, scene_corners[0], scene_corners[1], color, 20); //TOP line
    line( imgBRG2, scene_corners[1], scene_corners[2], color, 20);
    line( imgBRG2, scene_corners[2], scene_corners[3], color, 20);
    line( imgBRG2, scene_corners[3], scene_corners[0] , color, 20);
    
    addDebugImage(imgBRG2);

}

cv::vector<cv::vector<cv::Point>> GobanDetector::extractGobanState(UIImage* image, cv::vector<cv::Point> contourPoints)
{
    cv::Mat img = [PhotoKifuCore cvMatFromUIImage: image];

    return extractGobanState(img, contourPoints);
}


cv::vector<cv::vector<cv::Point>> GobanDetector::extractGobanState(cv::Mat& image, cv::vector<cv::Point> contourPoints)
{
    cv::Mat debugContour = image.clone();
    
    for (int i = 0; i < 4; i++)
    {
        line(debugContour, contourPoints[i], contourPoints[(i + 1) % 4], cv::Scalar(50, 255, 0), 5, CV_AA);
    }
    
    addDebugImage(debugContour, "Goban detection");
 
    
    // TODO: make this a single call for perf?
    cv::Mat matV = GetHSVChannel(image, HSV_VALUE, BLUR_NO);
    cv::Mat matH = GetHSVChannel(image, HSV_HUE, BLUR_NO);
    cv::Mat matS = GetHSVChannel(image, HSV_SATURATION, BLUR_NO);

    
    int warpSize = 1200;
    
    cv::Mat transform = getWarpTransform2(contourPoints, warpSize);
    
    cv::Mat warpedImage = warpImage(image, transform, warpSize, warpSize, CV_8UC3);
    addDebugImage(warpedImage, "warped Image");

    cv::Mat warpedMatV = warpImage(matV, transform, warpSize, warpSize, CV_8UC1);
    addDebugImage(warpedMatV, "warped Mat V");

//    cv::Mat warpedMatH = warpImage(matH, transform, warpSize, warpSize, CV_8UC1);
//    addDebugImage(warpedMatH, "warped Mat H");
    
//    cv::Mat warpedMatS = warpImage(matS, transform, warpSize, warpSize, CV_8UC1);
//    addDebugImage(warpedMatS, "warped Mat S");

    
/*    cv::Mat normalized;

    cv::normalize(warpedMatV, normalized, 0, 105, cv::NORM_MINMAX);
    
    addDebugImage(normalized, "normalized");
  */  

    
    cv::Mat blackOnly;


    cv::threshold(warpedMatV, blackOnly, 50, 255, CV_THRESH_BINARY);
    
    
    //cv::adaptiveThreshold(warpedMatV, blackOnly, 255, CV_THRESH_BINARY, CV_ADAPTIVE_THRESH_MEAN_C, 29, 15);
    
    //cv.AdaptiveThreshold(bwsrc, bwdst, 255.0, cv.CV_THRESH_BINARY, cv.CV_ADAPTIVE_THRESH_MEAN_C,11)

    addDebugImage(blackOnly, "Binary threshold");
    
    //        cv::blur(blackOnly, blackOnly, cv::Size(3, 3));
    
    dilate(blackOnly, blackOnly, cv::Mat(), cv::Point(-1, -1), 1);
    erode(blackOnly, blackOnly, cv::Mat(), cv::Point(-1, -1), 1);
    
    cv::bitwise_not(blackOnly, blackOnly);
    
    addDebugImage(blackOnly, "Dilate, erode and inverse colors");

    
/*
    for (int row = 0; row < warpedImage.rows; ++row)
    {
        uchar* p = warpedImage.ptr(row);
        
        for (int col = 0; col < warpedImage.cols; ++col)
        {
            p[0] = p[1] = p[2] = p[3] = p[0] & p[1] & p[2];
            
            p += 4;
        }
    }
*/
    
    /*{
    cv::Mat goban = extractStonePosition2(warpedMatV, warpedMatV);
    
    cv::Mat debugGoban = scaleImage(goban, 20);
    
    addDebugImage(debugGoban, "Test average");
    }*/
  
//    cv::adaptiveThreshold(warpedMatV, highlightWhite2, 255, CV_THRESH_BINARY_INV, CV_ADAPTIVE_THRESH_GAUSSIAN_C, 19, -15);

    addDebugImage(warpedImage, "warped color");

    testBlockAverage(warpedImage);
    
//    cv::blur(warpedImage, warpedImage, cv::Size(9, 9));
//    cv::blur(warpedImage, warpedImage, cv::Size(7, 7));
  //  cv::blur(warpedImage, warpedImage, cv::Size(5, 5));
    //cv::blur(warpedImage, warpedImage, cv::Size(3, 3));

    //addDebugImage(warpedImage, "warped color - mega blur");

    /*
    cv::Mat highlightWhite;
    
    for (int row = 0; row < warpedImage.rows; ++row)
    {
        uchar* p = warpedImage.ptr(row);
        
        for (int col = 0; col < warpedImage.cols; ++col)
        {
//            p[0] = p[1] = p[2] = p[3] = p[0] & p[1] & p[2];
            
            int sum = p[0] + p[1] + p[2];
            
            p[0] = p[0] * 255 / sum;
            p[1] = p[1] * 255 / sum;
            p[2] = p[2] * 255 / sum;
            

            int d1 = abs(p[0] - p[1]);
            int d2 = abs(p[0] - p[2]);
            int d3 = abs(p[1] - p[2]);
            
            int min = MIN(MIN(d1, d2), d3);
            
            p[0] = p[1] = p[2] = p[3] = min;
            
            p += 4;
        }
    }
    
    addDebugImage(warpedImage, "Hightlight white stones - min delta r g b");
    */

    int circleSizeMin = warpedMatV.rows / 21 / 2;
    int circleSizeMax = warpedMatV.rows / 19 / 2;
    int circleMinDist = warpedMatV.rows / 21;
    
//    cv::GaussianBlur(warpedMatS, warpedMatS, cv::Size(15, 15), 2, 2);

  //  addDebugImage(warpedMatS, "Blur");

//    cv::Mat edge_outputS;
//    edge_outputS = detectEdgesCanny(warpedMatS, 50);
//    addDebugImage(edge_outputS, "canny S");

//    cv::Mat edge_outputH;
//    edge_outputH = detectEdgesCanny(warpedMatH, 50);
//    addDebugImage(edge_outputH, "canny H");

    cv::Mat edge_outputV;
    edge_outputV = detectEdgesCanny(warpedMatV, 50);
    addDebugImage(edge_outputV, "canny V");

    cv::vector<cv::Vec3f> circles;
    /// Apply the Hough Transform to find the circles
    cv::HoughCircles(edge_outputV, circles, CV_HOUGH_GRADIENT, 1, circleMinDist, 50, 8, circleSizeMin, circleSizeMax);
    
    printf("Found %ld circles\r\n", circles.size());
    
    float dx = warpedMatV.rows / 18.0;
    
    cv::vector<cv::Point> allStones;
    
    /// Draw the circles detected
    for( size_t i = 0; i < circles.size(); i++ )
    {
        cv::Point center(cvRound(circles[i][0]), cvRound(circles[i][1]));
        
        int x = (center.x + dx / 2.0) / dx;
        int y = (center.y + dx / 2.0) / dx;
        
        int closestCenterX = x * dx;
        int closestCenterY = y * dx;

        int dstSqrt = pow(center.x - closestCenterX, 2) + pow(center.y - closestCenterY, 2);
        
        if (dstSqrt < pow(dx / 3, 2) * 2)
        {
            allStones.push_back(cv::Point(x, y));
            
            circle( warpedImage, cv::Point(closestCenterX, closestCenterY), 3, cv::Scalar(255,0,0), -1, 8, 0 );
            int radius = cvRound(circles[i][2]);
            // circle center
            circle( warpedImage, center, 3, cv::Scalar(0,255,0), -1, 8, 0 );
            // circle outline
            circle( warpedImage, center, radius, cv::Scalar(0,0,255), 3, 8, 0 );
        }
    }
    
    addDebugImage(warpedImage, "With circles");
    
    
    cv::vector<cv::Point> blackStones = extractBlackStones(blackOnly);
    
    cv::vector<cv::Point> whiteStones = deduceWhiteStones(allStones, blackStones);
    
//    cv::Mat binary;
    
    /*
    cv::cvtColor(warpedImage, binary, CV_BGR2GRAY);
    
    cv::Mat hist;
    cv::equalizeHist(binary, hist);
    addDebugImage(hist, "Hist");
     
    cv::threshold(binary, whiteOnly, 255 - 100, 255, CV_THRESH_BINARY_INV);
    */
    
//    cv::threshold(binary, whiteOnly, 50, 255, CV_THRESH_BINARY);

    /*
    dilate(whiteOnly, whiteOnly, cv::Mat(), cv::Point(-1, -1), 1);
    
    erode(whiteOnly, whiteOnly, cv::Mat(), cv::Point(-1, -1), 1);
    
    cv::bitwise_not(whiteOnly, whiteOnly);
    
    addDebugImage(whiteOnly, "Threshold, dilate, erode and inverse image");
    */
    
    
    
    //cv::Mat goban = extractStonePosition(blackOnly, whiteOnly);
    
    //cv::Mat debugGoban = scaleImage(goban, 20);
    
    //addDebugImage(debugGoban, "Final result");
    
    //cv::vector<cv::vector<cv::Point>> stones = extractStones(goban);
    
    cv::vector<cv::vector<cv::Point>> stones;
    
    stones.push_back(blackStones);
    stones.push_back(whiteStones);
    
    //= extractStones(goban);
    
    return stones;   
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
    
    /*
    if (channel == HSV_VALUE)
    {
        addDebugImage(channels[2], "V channel");
    }
    
    if (channel == HSV_SATURATION)
    {
        addDebugImage(channels[1], "S channel");
    }
    
    if (channel == HSV_HUE)
    {
        addDebugImage(channels[0], "H channel");
    }
     */
    
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

    
//    detectGobanLines(edge_output, lines, image);
    
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

    /*
    const char* letters = "abcdefghijklmnopqrstuvwxyz";
//    const char* letters = "\x0061\x0062\x0063\x0064\x0065\x0066\x0067\x0068\x0069\x006A\x006B\x006C\x006D\x006E\x006F\x0070\x0071\x0072\x0073\x0074\x0075\x0076\x0077\x0078\x0079\x007A";
    
    std::ostringstream oss; // string as stream
    
    oss << "(;GM[1]SZ[19]FF[4]";

    if (blackStones.size() > 0)
    {
        oss << "AB";
        
        for (cv::vector<int>::iterator it = blackStones.begin(); it != blackStones.end(); ++it)
        {
            int coord = *it;
            
            char x = letters[coord >> 4];
            char y = letters[coord - x];
            
            oss << "[" << x << y << "]";
        }
    }
    
    if (whiteStones.size() > 0)
    {
        oss << "AW";

        for (cv::vector<int>::iterator it = whiteStones.begin(); it != whiteStones.end(); ++it)
        {
            int coord = *it;
            
            char x = letters[coord >> 4];
            char y = letters[coord - x];
            
            oss << "[" << x << y << "]";
        }
    }
    
    oss << ")";
    
    std::string sgf = oss.str(); // get string out of stream
    
    return sgf.c_str();
     */
}

cv::Mat GobanDetector::extractStonePosition2(cv::Mat blackStones, cv::Mat whiteStones)
{
    cv::Mat goban = cv::Mat::zeros(19, 19, CV_8UC1);
    
    //goban.setTo(cv::Scalar(128, 128, 128));
    
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
            
            goban.at<uchar>(i, j) = (uchar) mean[0];
            
            /*
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
             */
            
            // debug
            rectangle(blackStones, cv::Point(xMin, yMin), cv::Point(xMax, yMax), cv::Scalar(100));
            rectangle(whiteStones, cv::Point(xMin, yMin), cv::Point(xMax, yMax), cv::Scalar(100));
            
        }
    }
    
    addDebugImage(blackStones, "Black stones detection (the grid position is arbitrary, work in progress)");
    addDebugImage(whiteStones, "White stones detection (the grid position is arbitrary, work in progress)");
    
    //    goban.at<uchar>(1, 1) = 255;
    
    
    return goban;
}

void GobanDetector::testBlockAverage(cv::Mat warpedImage)
{
    cv::Mat result = cv::Mat(warpedImage.cols, warpedImage.rows, CV_8UC3);
        
    for (int i = 0; i < 19; i++)
    {
        for (int j = 0; j < 19; j++)
        {
            float dx = warpedImage.cols / 18.0;
            float dy = warpedImage.rows / 18.0;
            
            int x1 = -dx / 2;
            int y1 = -dy / 2;
            
            int xMin = MAX(0, x1 + dx * i);
            int xMax = MIN(warpedImage.cols - 1, x1 + dx * (i + 1) - 1);
            
            int yMin = MAX(0, y1 + dy * j);
            int yMax = MIN(warpedImage.rows - 1, y1 + dy * (j + 1) - 1);
            
            cv::Mat block = warpedImage.rowRange(xMin, xMax).colRange(yMin, yMax);
            
            cv::Scalar mean = cv::mean(block);
            
            cv::Mat targetBlock = result.rowRange(xMin, xMax).colRange(yMin, yMax);

            targetBlock.setTo(mean);
            
            /*
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
            */
            
            // debug
            rectangle(warpedImage, cv::Point(xMin, yMin), cv::Point(xMax, yMax), cv::Scalar(100));
            rectangle(warpedImage, cv::Point(xMin, yMin), cv::Point(xMax, yMax), cv::Scalar(100));
             
        }
    }
    
    addDebugImage(warpedImage, "average block segmentation");
    addDebugImage(result, "average block result");
    
    
    // need to create a point system.
    // -> points for average color detection
    // -> points for circle detection
    // -> points for XXX
    
    
    //    goban.at<uchar>(1, 1) = 255;
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

//    goban.at<uchar>(1, 1) = 255;


    return goban;
}

cv::Mat GobanDetector::warpImage(cv::Mat& image, cv::Mat& transform, int dstWidth, int dstHeight, int dstImageFormat)
{
    // Define the destination image
    cv::Mat quad = cv::Mat::zeros(dstWidth, dstHeight, dstImageFormat);
        
    // Apply perspective transformation
    cv::warpPerspective(image, quad, transform, quad.size());
    
    //addDebugImage(quad, "Warp perspective");
    
    return quad;
}

cv::Mat GobanDetector::getWarpTransform(cv::vector<cv::Point> poly)
{/*
    int maxDistance = 0;
    maxDistance = MAX(maxDistance, cv::norm(poly[0] - poly[1]));
    maxDistance = MAX(maxDistance, cv::norm(poly[1] - poly[2]));
    maxDistance = MAX(maxDistance, cv::norm(poly[2] - poly[3]));
    maxDistance = MAX(maxDistance, cv::norm(poly[3] - poly[0]));
   */ 
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
    
//    corners.pop_back();
//    quad_pts.pop_back();
    
    // Get transformation matrix
    cv::Mat transmtx = cv::getPerspectiveTransform(corners, quad_pts);
//    cv::Mat transmtx = cv::getAffineTransform(corners, quad_pts);
    
    return transmtx;
}

cv::Mat GobanDetector::getWarpTransform3(cv::Mat &image, cv::vector<cv::Point> poly)
{/*
  int maxDistance = 0;
  maxDistance = MAX(maxDistance, cv::norm(poly[0] - poly[1]));
  maxDistance = MAX(maxDistance, cv::norm(poly[1] - poly[2]));
  maxDistance = MAX(maxDistance, cv::norm(poly[2] - poly[3]));
  maxDistance = MAX(maxDistance, cv::norm(poly[3] - poly[0]));
  */
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
    
    //    corners.pop_back();
    //    quad_pts.pop_back();
    
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

void GobanDetector::testLines()
{/*
  
  // Other method: Line detection
  
  {
  cv::Mat line1 = image.clone();
  cv::vector<cv::Vec4i> lines;
  cv::HoughLinesP(canny_output.clone(), lines, 1, CV_PI / 180, 100, 100, 8);
  
  const int lineCount = MIN(33300, lines.size());
  
  for (size_t i = 0; i < lineCount; i++)
  {
  cv::Vec4i l = lines[i];
  
  line(line1, cv::Point(l[0], l[1]), cv::Point(l[2], l[3]), cv::Scalar(110, 110, 255), 9, CV_AA);
  }
  
  addDebugImage(line1);
  }

  
    {
        cv::vector<cv::Vec2f> lines;
        cv::HoughLines(canny_output, lines, 1, CV_PI / 180, 1);
  
        // const int lineCount = MIN(100, lines.size());
        const int lineCount = lines.size();
        
        //double angleTolerance = CV_PI / 180 * 10; // 10 degrees of vectical / horizontal
        
        cv::Mat line1 = image.clone();
        
        for (int i = 0; i < lineCount; i++)
        {
            int res = 1000;
            float rho = lines[i][0], theta = lines[i][1];
            
            //if (theta < angleTolerance ||
            //    (theta > (CV_PI / 2 - angleTolerance) && theta < (CV_PI / 2 + angleTolerance)) ||
            //    theta > (CV_PI - angleTolerance))
            {
                cv::Point pt1, pt2;
                double a = cos(theta), b = sin(theta);
                double x0 = a * rho, y0 = b * rho;
                pt1.x = cvRound(x0 + res * (-b));
                pt1.y = cvRound(y0 + res * (a));
                pt2.x = cvRound(x0 - res * (-b));
                pt2.y = cvRound(y0 - res * (a));
                
                line(line1, pt1, pt2, cv::Scalar(110, 110, 255), 9, CV_AA);
            }
            
        }
        
        addDebugImage(line1);
    }
  */
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
        
        if (contours_poly[i].size() == 4
            && area > 10000
            && isContourConvex(cv::Mat(contours_poly[i])))
        {
            double maxCosine = 0;
            
            for( int j = 2; j < 5; j++ )
            {
                cv::Point pt0 = contours_poly[i][j-1];
                
                double cosine = fabs(angle(contours_poly[i][j%4], contours_poly[i][j-2], pt0));
                maxCosine = MAX(maxCosine, cosine);
            }
            
            cv::drawContours(debugAllQuadConvecContours, contours, i, cv::Scalar((13 *  i) % 255, (131 *  i) % 255, (1313 *  i) % 255), 5, 8);

            if (maxCosine < 0.7)
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
    
    return cv::vector<cv::Point>(contours_poly[largestPolyIndex]);
}

bool GobanDetector::detectPlanarHomography(cv::Mat& image, cv::Point vanishingPoint1, cv::Point vanishingPoint2)
{
    return true;
}

std::vector<std::vector<cv::Point>> applyPerspectiveToLineCluster(std::vector<std::vector<cv::Point>> lines, cv::Mat &h)
{
    cv::vector<cv::Point2f> pointsToTransform;
    
    for (int i = 0; i < lines.size(); i++)
    {
        pointsToTransform.push_back(cv::Point2f(lines[i][0].x, lines[i][0].y));
        pointsToTransform.push_back(cv::Point2f(lines[i][1].x, lines[i][1].y));
    }
    
    cv::vector<cv::Point2f> transformedPoints(pointsToTransform.size());
    
    perspectiveTransform(pointsToTransform, transformedPoints, h);
    
    std::vector<std::vector<cv::Point>> result;
    
    for (int i = 0; i < transformedPoints.size(); i += 2)
    {
        std::vector<cv::Point> line;
        
        line.push_back(cv::Point(transformedPoints[i].x, transformedPoints[i].y));
        line.push_back(cv::Point(transformedPoints[i + 1].x, transformedPoints[i + 1].y));
        
        result.push_back(line);
    }
    
    return result;
}


bool GobanDetector::detectGobanLines(cv::Mat& image, cv::vector<cv::Vec4i> gobanLines, cv::Mat& sourceImage)
{    
    cv::Mat line1 = image.clone();

    cv::Mat debugConv = cv::Mat(line1.size(), CV_8UC3, cv::Scalar(180, 180, 180));
    cv::Mat debugConv3 = sourceImage; // cv::Mat(line1.size(), CV_8UC3, cv::Scalar(180, 180, 180));
    
    int minPixelsToFormALine = MAX(10, image.cols / 25);
    int maxLineGap = MIN(5, image.cols / 100);

    cv::vector<cv::Vec4i> lines;
    
    cv::HoughLinesP(image.clone(), lines, 1, CV_PI / 180, 100, minPixelsToFormALine, maxLineGap);
    
    const int lineCount = MIN(1000, lines.size());
    
    cv::vector<cv::vector<cv::Point>> lineSegments;
    cv::vector<cv::vector<cv::Point>> lineSegmentsDeleted;
    cv::vector<cv::Point> aux;

    int angleMarginInDegrees = 3;
    int deltaMargin = 20;
    
    cv::vector<lineData> linesData;
    linesData.reserve(lineCount);
    
    for (size_t i = 0; i < lineCount; i++)
    {
        cv::Vec4i l = lines[i];
        
        lineData ld;
        
		ld.pt1.x = l[0];
		ld.pt1.y = l[1];
		ld.pt2.x = l[2];
		ld.pt2.y = l[3];

        pointsToNormalForm(ld.pt1, ld.pt2, ld.rho, ld.theta);
     
        cv::Point debugPt1;
        cv::Point debugPt2;
        
        // debug
        normalFormToPoint(ld.rho, ld.theta, debugPt1, debugPt2);
        cv::line(debugConv, debugPt1, debugPt2, cv::Scalar(0, 0, 255), 2, CV_AA);
        cv::line(debugConv, ld.pt1, ld.pt2, cv::Scalar(0, 255, 0), 2, CV_AA);

        ld.norm = dist(ld.pt1, ld.pt2);

//        int similarLineIndex = -1;
        
        cv::vector<int> similarLineIndexes;
        
        for (int j = 0; j < i; j++)
        {
            lineData processedLine = linesData[j];
            if (processedLine.retain)
            {
                // 100 and 98 -> delta = 2
                // 100 and -98 -> sum = -2
             
                if (ld.rho < 0)
                {
                    ld.rho = ld.rho;
                }
        
                if (ld.rho > 0)
                {
                    ld.rho = ld.rho;
                }
                
                float deltaRho = abs(ld.rho - processedLine.rho);
                float sumRho = abs(ld.rho + processedLine.rho);
                float deltaTheta = abs(ld.theta - processedLine.theta);
                
                bool foundSimilar = false;
                            
                // is there already a line similar to this one?
                if (deltaRho < deltaMargin && deltaTheta < angleMarginInDegrees)
                {
                    foundSimilar = true;
                }                
                
                if (sumRho < deltaMargin)
                {
                    if (deltaTheta > 180 - angleMarginInDegrees)
                    {
                        foundSimilar = true;
                    }
                }
                
                if (foundSimilar)
                {
                    similarLineIndexes.push_back(j);
                }
            }
        }
        
        if (similarLineIndexes.size() == 0)
        {
            ld.retain = true;
        }
        else
        {
            for (int i = 0; i < similarLineIndexes.size(); i++)
            {
                lineData *similarLine = &linesData[similarLineIndexes[i]];
                
                if (ld.norm > similarLine->norm)
                {
                    // replace segment with the new, longer one (more precise)
                    similarLine->retain = false;
                    
                    //lineData s2 = linesData[similarLineIndexes[i]];
                    
                    //std::cout << "Replacing index " << similarLineIndex << " with  " << i << "(" << similarLine->norm << " -> " << ld.norm << ")\r\n";
                    
                    ld.retain = true;
                }
                else
                {
                    ld.retain = false;
                    
                    // This could be improved. We don't have to break, there could be strange cases
                    break;
                }
            }
        }
        
        linesData.push_back(ld);
    }
    
    addDebugImage(debugConv, "Convertion to normal form");
    
    std::vector<std::vector<cv::Point>> lineSegmentsClusters1;
    std::vector<std::vector<cv::Point>> lineSegmentsClusters2;
    
    float referenceAngle = linesData[0].theta;
    
    
    cv::Mat debugConv2 = cv::Mat(line1.size(), CV_8UC3, cv::Scalar(180, 180, 180));

    
    for (int i = 0; i < linesData.size(); i++)
    {
        lineData *ld = &linesData[i];
     
        aux.clear();
        aux.push_back(ld->pt1);
        aux.push_back(ld->pt2);
        
        if (ld->retain)
        {
            float deltaAngle = abs(referenceAngle - ld->theta);
            
            if (deltaAngle < 45 || deltaAngle > 180 - 45)
            {
                lineSegmentsClusters1.push_back(aux);
            }
            else
            {
                lineSegmentsClusters2.push_back(aux);
            }
            
            cv::line(debugConv2, ld->pt1, ld->pt2, cv::Scalar(i / 255, i % 255, 255), 2);
            
            //std::cout << "Retain " << i / 255 << " " << i % 255 << " rho = " << ld->rho << "\t theta = " << ld->theta << "\r\n";
            
            //lineSegments.push_back(aux);
        }
        else
        {
            lineSegmentsDeleted.push_back(aux);
        }
    }

    addDebugImage(debugConv2, "After line merge");
    
    std::cout << "HoughLines: " << lineCount << "   After merge: " << lineSegmentsClusters1.size() + lineSegmentsClusters2.size() << "   Deleted: " << lineSegmentsDeleted.size() << "\r\n";

    cv::Mat clusterMap = cv::Mat(line1.size(), CV_8UC3, cv::Scalar(180, 180, 180));
    
    for (int i = 0; i < lineSegmentsClusters1.size(); i++)
    {
        std::vector<cv::Point> line = lineSegmentsClusters1[i];

        {
        // debug
        float rho, theta;
        pointsToNormalForm(line[0], line[1], rho, theta);
        
        cv::Point debugPt1;
        cv::Point debugPt2;
        
        // debug
        normalFormToPoint(rho, theta, debugPt1, debugPt2);
        cv::line(debugConv3, debugPt1, debugPt2, cv::Scalar(0, 0, 255), 2, CV_AA);
        }
        
        cv::line(clusterMap, line[0], line[1], cv::Scalar(0, 255, 0), 3, CV_AA);
    }

    for (int i = 0; i < lineSegmentsClusters2.size(); i++)
    {
        std::vector<cv::Point> line = lineSegmentsClusters2[i];
        
        {
            // debug
            float rho, theta;
            pointsToNormalForm(line[0], line[1], rho, theta);
            
            cv::Point debugPt1;
            cv::Point debugPt2;
            
            // debug
            normalFormToPoint(rho, theta, debugPt1, debugPt2);
            cv::line(debugConv3, debugPt1, debugPt2, cv::Scalar(0, 0, 255), 5, CV_AA);
        }

        
        cv::line(clusterMap, line[0], line[1], cv::Scalar(0, 0, 255), 3, CV_AA);
    }

    addDebugImage(debugConv3, "After merge, infinite lines");
    addDebugImage(clusterMap, "Cluster Map");
        
    //std::vector<cv::Point> gobanCorners = detectGobanCorners(debugConv2, lineSegmentsClusters1, lineSegmentsClusters2);
    
    
    
    std::cout << "[" << lineSegmentsClusters1.size() << ", " << lineSegmentsClusters2.size() << "]";

    std::vector<std::vector<std::vector<cv::Point>>> lineSegmentsClusters;
    lineSegmentsClusters.push_back(lineSegmentsClusters1);
    lineSegmentsClusters.push_back(lineSegmentsClusters2);

    cv::Point intersectionA;
    cv::Point intersectionB;
    cv::Point intersectionC;
    cv::Point intersectionD;
    

    
    int minLineLenght = image.rows / 200;
//    int minDistanceBetweenLines = image.cols / 200;
    
//    std::vector<cv::Point> corners = getIntersections(minLineLenght, minDistanceBetweenLines, lineSegmentsClusters);
    std::vector<cv::Point> corners = getLargestIntersections(minLineLenght, lineSegmentsClusters);

    if (corners.size() != 4)
    {
        return false;
    }

    cv::Mat intersectionDebug = image.clone();
    
    circle(intersectionDebug, corners[0], 40, cv::Scalar(250, 250, 250), 20);
    circle(intersectionDebug, corners[1], 40, cv::Scalar(250, 250, 250), 20);
    circle(intersectionDebug, corners[2], 40, cv::Scalar(250, 250, 250), 20);
    circle(intersectionDebug, corners[3], 40, cv::Scalar(250, 250, 250), 20);
    
    addDebugImage(intersectionDebug, "Intersection Debug - step 1");

    
//    cv::Mat transform = getWarpTransform3(image, corners);

    cv::Mat transform = getWarpTransform2(corners, 500);
    
    printf("Transform matrix:\r\n");
    printf("[ %3.3f %3.3f %3.3f]\r\n", transform.at<double>(0, 0), transform.at<double>(0, 1), transform.at<double>(0, 2));
    printf("[ %3.3f %3.3f %3.3f]\r\n", transform.at<double>(1, 0), transform.at<double>(1, 1), transform.at<double>(1, 2));
    printf("[ %3.3f %3.3f %3.3f]\r\n", transform.at<double>(2, 0), transform.at<double>(2, 1), transform.at<double>(2, 2));
    

    std::vector<std::vector<cv::Point>> newCluster1 = applyPerspectiveToLineCluster(lineSegmentsClusters1, transform);
    std::vector<std::vector<cv::Point>> newCluster2 = applyPerspectiveToLineCluster(lineSegmentsClusters2, transform);

    
    std::vector<cv::Point> minMax = findMinMaxPoints(newCluster1, newCluster2);
    
    printf("MinMax: (%i, %i) -> (%i, %i)\r\n", minMax[0].x, minMax[0].y, minMax[1].x, minMax[1].y);
    
//    perspectiveTransform(obj_corners, scene_corners, H);
    
    // Define the destination image
    int dstWidth = image.cols;
    int dstHeight = image.rows;
  
    cv::Mat invTransform = transform.inv();
    
    std::vector<cv::Point2f> quad_pts;
    quad_pts.push_back(cv::Point2f(0, 0));
    quad_pts.push_back(cv::Point2f(dstWidth, 0));
    quad_pts.push_back(cv::Point2f(dstWidth, dstHeight));
    quad_pts.push_back(cv::Point2f(0, dstHeight));
    
    std::vector<cv::Point2f> invQuad(4);
    
    perspectiveTransform(quad_pts, invQuad, invTransform);
    
    for (int i = 0; i < invQuad.size(); i++)
    {
        line(clusterMap, invQuad[i], invQuad[(i + 1) % 4], cv::Scalar(0, 255, 255), 5);
    }
    
    addDebugImage(clusterMap, "Cluster Map");

    cv::Mat quad = cv::Mat::zeros(dstWidth, dstHeight, CV_8UC3);
    
    for (int i = 0; i < newCluster1.size(); i++)
    {
        line(quad, newCluster1[i][0], newCluster1[i][1], cv::Scalar(0, 0, 255), 5);
    }

    for (int i = 0; i < newCluster2.size(); i++)
    {
        line(quad, newCluster2[i][0], newCluster2[i][1], cv::Scalar(0, 0, 255), 5);
    }

    line(quad, cv::Point(0, 0), cv::Point(200, 200), cv::Scalar(0, 0, 255), 15);

    addDebugImage(quad, "Warped cluster 1");
    
    std::vector<cv::Point> gobanCorners = detectGobanCorners(quad, newCluster1, newCluster2);

    
    // Apply perspective transformation
//    cv::warpPerspective(clusterMap, quad, transform, quad.size());
    
//    addDebugImage(quad, "Warp whole image");
    
    //cv::warpAffine(image, quad, transform, quad.size());
    
    //addDebugImage(quad, "Warp whole image (affine)");
    
    return true;
}

std::vector<std::vector<cv::Point>> generateGrid(cv::Mat &image, cv::Point p1, cv::Point p2, cv::Point p3, cv::Point p4, int intervalCount)
{
    cv::Point2d v1 = getVector(p1, p2, intervalCount);
    cv::Point2d v2 = getVector(p3, p4, intervalCount);
        
    std::vector<std::vector<cv::Point>> result;
    
    cv::Point2d pointA = p1, pointB = p3;

    // add starting point
    result.push_back(point2dToLine(pointA, pointB));

    // go in one direction
    while (inside(pointA, image.cols, image.rows) && inside(pointB, image.cols, image.rows))
    {
        pointA += v1;
        pointB += v2;
        
        result.push_back(point2dToLine(pointA, pointB));
    }

    // back to the start
    pointA = p1, pointB = p3;

    // go in the other direction
    while (inside(pointA, image.cols, image.rows) && inside(pointB, image.cols, image.rows))
    {
        pointA -= v1;
        pointB -= v2;
        
        result.push_back(point2dToLine(pointA, pointB));
    }

    return result;
}

double computeGridDistance(std::vector<std::vector<cv::Point>> grid, std::vector<std::vector<cv::Point>> lineSegments)
{
    double totalDistance = 0;
    
    for (int s = 0; s < lineSegments.size(); s++)
    {
        double distanceToClosestSegment = 999999999;
        
        for (int g = 0; g < grid.size(); g++)
        {
            double distance = distanceBetweenLines(lineSegments[s], grid[g]);
            
            if (distance < distanceToClosestSegment)
            {
                distanceToClosestSegment = distance;
            }
        }
        
        totalDistance += distanceToClosestSegment;
    }
    
    return totalDistance;
}

double computeGridDistance2(std::vector<std::vector<cv::Point>> grid, double gridSpacing, std::vector<std::vector<cv::Point>> lineSegments)
{
    int matchingLineCount = 0;
    int nonMatchingLineCount = 0;
    
    double acceptableDistance = gridSpacing / 5;
    for (int g = 0; g < grid.size(); g++)
    {
        double distanceToClosestSegment = 999999999;
        
        for (int s = 0; s < lineSegments.size(); s++)
        {
            double distance = distanceBetweenLines(lineSegments[s], grid[g]);
            
            if (distance < distanceToClosestSegment)
            {
                distanceToClosestSegment = distance;
            }
        }

        if (distanceToClosestSegment < acceptableDistance)
        {
            matchingLineCount++;
        }
        else
        {
            nonMatchingLineCount++;
        }
    }
    
    // remove edge cases
    if (matchingLineCount < 5)
    {
        return 9999;
    }
    
    // offset is there to make sure the total is high enough when the interval is quite big and few grid lines are used.
    int offset = 10;
    
    double total = offset + nonMatchingLineCount + matchingLineCount + 1;
    double validCount = matchingLineCount + 1;
    double ratio = total / (validCount * validCount);
    
    printf("nmc: %i   mc: %i   ratio = %f\r\n", nonMatchingLineCount, matchingLineCount, ratio);
    
    return ratio;
}

std::vector<cv::Point> GobanDetector::detectGobanCorners(cv::Mat &image, std::vector<std::vector<cv::Point>> lineSegmentsClusters1, std::vector<std::vector<cv::Point>> lineSegmentsClusters2)
{
    std::vector<cv::Point> corners;
    
    int minLineLength = image.rows / 20;
    int minDistanceBetweenLines = image.cols / 20;

    std::vector<std::vector<std::vector<cv::Point>>> lineSegmentsClusters;
    lineSegmentsClusters.push_back(lineSegmentsClusters1);
    lineSegmentsClusters.push_back(lineSegmentsClusters2);
    
    std::vector<cv::Point> bestQuadri;
    
    double minDistance = 9999999999;
    std::vector<std::vector<cv::Point>> bestGrid;

    for (int iter = 0; iter < 5; iter++)
    {
        std::vector<cv::Point> quadri = getIntersections(minLineLength, minDistanceBetweenLines, lineSegmentsClusters);
        
        if (quadri.size() != 4)
        {
            continue;
        }
        
        quadri = sortSquarePointsClockwise(quadri);
                
        for (int interval = 3; interval < 19; interval++)
        {
            // the order of the corners is important
            std::vector<std::vector<cv::Point>> grid = generateGrid(image, quadri[0], quadri[1], quadri[3], quadri[2], interval);
            
            /*
             line(debug, quadri[0], quadri[1], cv::Scalar(255, 0, 0), 5);
             line(debug, quadri[3], quadri[2], cv::Scalar(255, 0, 0), 5);
             
             for (int i = 0; i < grid.size(); i++)
             {
             line(debug, grid[i][0], grid[i][1], cv::Scalar(255, 255, 0), 5);
             }
             
             addDebugImage(debug);
             
             break;
             */
            
            std::vector<std::vector<cv::Point>> *matchingCluster;
            
            if (vertical(lineSegmentsClusters1))
            {
                matchingCluster = &lineSegmentsClusters1;
            }
            else
            {
                matchingCluster = &lineSegmentsClusters2;
            }
            
            cv::Point2d v1 = getVector(quadri[0], quadri[1], interval);
            //cv::Point2d v2 = getVector(quadri[3], quadri[2], interval);
            
            double normV1 = cv::norm(v1);
            
            if (normV1 < 0.1)
            {
                printf("[low] ");
            }

//            printf("interval: %i  (norm = %.2f)\r\n", interval, normV1);
            double distance = computeGridDistance2(grid, normV1, *matchingCluster);
            
            /*
            cv::Mat debug = image.clone();
            
            line(debug, quadri[0], quadri[1], cv::Scalar(255, 0, 0), 5);
            line(debug, quadri[3], quadri[2], cv::Scalar(255, 0, 0), 5);
            
            for (int i = 0; i < grid.size(); i++)
            {
                line(debug, grid[i][0], grid[i][1], cv::Scalar(255, 255, 0), 5);
            }

            char text[200];
            sprintf(text, "%i dist = %f", interval, distance);

            putText(debug, text, cvPoint(30, 230), cv::FONT_HERSHEY_COMPLEX_SMALL, 8, cvScalar(200, 200, 250), 5, CV_AA);
            
            addDebugImage(debug, "Grid");
             */
            
            
            if (distance < minDistance)
            {
                printf("New min distance: %f\r\n", distance);
                
                minDistance = distance;
                bestGrid = grid;
                bestQuadri = quadri;
            }
        }
        
        /*
        cv::Mat debug = image.clone();
        
        line(debug, bestQuadri[0], bestQuadri[1], cv::Scalar(255, 0, 0), 5);
        line(debug, bestQuadri[3], bestQuadri[2], cv::Scalar(255, 0, 0), 5);
        
        for (int i = 0; i < bestGrid.size(); i++)
        {
            line(debug, bestGrid[i][0], bestGrid[i][1], cv::Scalar(255, 255, 0), 5);
        }
        
        addDebugImage(debug, "Best grid iteration...");
         */
    }
    
    if (bestQuadri.size() == 0)
    {
        printf("Could not find best quadri");
        return corners;
    }
    
    cv::Mat debug = image.clone();
    
    line(debug, bestQuadri[0], bestQuadri[1], cv::Scalar(255, 0, 0), 5);
    line(debug, bestQuadri[3], bestQuadri[2], cv::Scalar(255, 0, 0), 5);
    
    for (int i = 0; i < bestGrid.size(); i++)
    {
        line(debug, bestGrid[i][0], bestGrid[i][1], cv::Scalar(255, 255, 0), 5);
    }
    
    addDebugImage(debug, "Best grid");
    
    return bestQuadri;
}


std::vector<std::vector<cv::Point>> GobanDetector::selectLines(int minLineLength, int minDistanceBetweenLines, std::vector<std::vector<cv::Point>> lineSegments)
{
    std::vector<std::vector<cv::Point>> selectedLines;
    
    int rnd = rng.next() % 123456;
    
    for (int i = 0; i < lineSegments.size(); i++)
    {
        int index = (rnd + i) % lineSegments.size();
//        printf("index %i \r\n", index);
        
        std::vector<cv::Point> line = lineSegments[index];
        
        cv::Point p1 = line[0];
        cv::Point p2 = line[1];
        
        double norm = dist(p1, p2);
        
      //  printf("  norm = %f\r\n", norm);
        
        if (norm > minLineLength)
        {
            double dist = 999999;
            
            if (selectedLines.size() > 0)
            {
                //printf("  [%i, %i] to [%i ,%i] => [%i, %i]\r\n", p1.x, p1.y, p2.x, p2.y, selectedLines[0][0].x, selectedLines[0][0].y);

                dist = distanceBetweenLineAndPoint(p1, p2, selectedLines[0][0]);

               // printf("  dist = %f\r\n", dist);
            }
            
            if (dist > minDistanceBetweenLines)
            {
                selectedLines.push_back(line);
               // printf("  pushing back!\r\n");
            }
            
            if (selectedLines.size() >= 2)
            {
                break;
            }
        }
    }
    
    //printf("\r\n");

    return selectedLines;
}

std::vector<cv::Point> GobanDetector::getIntersections(std::vector<std::vector<cv::Point>> lines1, std::vector<std::vector<cv::Point>> lines2)
{
    std::vector<cv::Point> corners;

    if (lines1.size() != 2 || lines2.size() != 2)
    {
        std::cout << "Error: could not find 2 lines for each pespective cluster" << "\r\n";
        return corners;
    }
    
    cv::Point intersectionA;
    cv::Point intersectionB;
    cv::Point intersectionC;
    cv::Point intersectionD;
    
    std::vector<cv::Point> lineA;
    std::vector<cv::Point> lineB;
    
    
    lineA = lines1[0];
    lineB = lines2[0];
    intersection(lineA[0], lineA[1], lineB[0], lineB[1], intersectionA);
    
    if (intersectionA.x == 0 && intersectionA.y == 0)
    {
        printf("intersection at 0,0 -> suspicious\r\n");
    }
    
    lineA = lines1[1];
    lineB = lines2[0];
    intersection(lineA[0], lineA[1], lineB[0], lineB[1], intersectionB);
    
    lineA = lines1[0];
    lineB = lines2[1];
    intersection(lineA[0], lineA[1], lineB[0], lineB[1], intersectionC);
    
    lineA = lines1[1];
    lineB = lines2[1];
    intersection(lineA[0], lineA[1], lineB[0], lineB[1], intersectionD);
    
    corners.push_back(intersectionA);
    corners.push_back(intersectionB);
    corners.push_back(intersectionC);
    corners.push_back(intersectionD);
    
    return corners;
}

std::vector<cv::Point> GobanDetector::getIntersections(int minLineLength, int minDistanceBetweenLines, std::vector<std::vector<std::vector<cv::Point>>> lineSegmentsClusters)
{
    std::vector<std::vector<cv::Point>> firstSet = lineSegmentsClusters[0];
    std::vector<std::vector<cv::Point>> secondSet = lineSegmentsClusters[1];
    
    std::vector<std::vector<cv::Point>> lines1 = selectLines(minLineLength, minDistanceBetweenLines, firstSet);
    std::vector<std::vector<cv::Point>> lines2 = selectLines(minLineLength, minDistanceBetweenLines, secondSet);

    return getIntersections(lines1, lines2);
}

std::vector<cv::Point> GobanDetector::getLargestIntersections(int minLineLength, std::vector<std::vector<std::vector<cv::Point>>> lineSegmentsClusters)
{
    std::vector<cv::Point> corners;
    
    std::vector<std::vector<cv::Point>> firstSet = lineSegmentsClusters[0];
    std::vector<std::vector<cv::Point>> secondSet = lineSegmentsClusters[1];
    
    std::vector<std::vector<cv::Point>> lines1 = selectExtremeLines(minLineLength, firstSet);
    std::vector<std::vector<cv::Point>> lines2 = selectExtremeLines(minLineLength, secondSet);
    
    return getIntersections(lines1, lines2);
}



// return the transposition of the passingBy point parallel to the line (a, b)
cv::Point GobanDetector::linePassingByPoint(cv::Point a, cv::Point b, cv::Point passingBy)
{
    cv::Point r;
    
    r.x = passingBy.x + b.x - a.x;
    r.y = passingBy.y + b.y - a.y;
    
    return r;
}

// check wich line is closer to the passingBy point and return the transposition of the passingBy point parallel to that line
cv::Point GobanDetector::closestLinePassingByPoint(cv::vector<cv::Point> l1, cv::vector<cv::Point> l2, cv::Point passingBy)
{
    double distL1 = distanceBetweenLineAndPoint(l1[0], l1[1], passingBy);
    double distL2 = distanceBetweenLineAndPoint(l2[0], l2[1], passingBy);
    
    cv::Point r;
    
    if (distL1 < distL2)
    {
        r = linePassingByPoint(l1[0], l1[1], passingBy);
    }
    else
    {
        r = linePassingByPoint(l2[0], l2[1], passingBy);
    }
    
    return r;
}

//bool GobanDetector::intersectionWithEdge(cv::Point a1, cv::Point a2, cv::Point b1, cv::Point b2, cv::Rect edges, std::vector<cv::Point> &corners)
bool GobanDetector::intersectionWithEdge(cv::vector<cv::Point> a, cv::vector<cv::Point> b, cv::vector<cv::Point> a2, cv::vector<cv::Point> b2, cv::Rect edges, std::vector<cv::Point> &corners)
{
    cv::Point va = a[0] - a[1];
    cv::Point vb = b[0] - b[1];
    cv::Point va2 = a2[0] - a2[1];
    cv::Point vb2 = b2[0] - b2[1];
    
    int vaDir = va.x * va.y;
    int vbDir = vb.x * vb.y;
    int va2Dir = va2.x * va2.y;
    int vb2Dir = vb2.x * vb2.y;
    
    if (vaDir == vbDir || va2Dir == vb2Dir)
    {
        std::cout << "Error: intersectionWithEdge got to vectors going in the same direction";
        
        return false;
    }
    
    cv::Point edgeV0 = edges.tl();
    cv::Point edgeV1 = cv::Point(edgeV0.x + edges.width, edgeV0.y);
    cv::Point edgeV2 = edges.br();
    cv::Point edgeV3 = cv::Point(edgeV0.x, edgeV0.y + edges.height);

    cv::Point v0;
    cv::Point v1;
    cv::Point v2;
    cv::Point v3;

    if (vaDir >= 0)
    {
        v0 = closestLinePassingByPoint(b, b2, edgeV0);
        v1 = closestLinePassingByPoint(a, a2, edgeV1);
        v2 = closestLinePassingByPoint(b, b2, edgeV2);
        v3 = closestLinePassingByPoint(a, a2, edgeV3);
    }
    else
    {
        v0 = closestLinePassingByPoint(a, a2, edgeV0);
        v1 = closestLinePassingByPoint(b, b2, edgeV1);
        v2 = closestLinePassingByPoint(a, a2, edgeV2);
        v3 = closestLinePassingByPoint(b, b2, edgeV3);
    }
    
    cv::Point intersectionPoint;
        
    if (intersection(edgeV0, edgeV0 + v0, edgeV1, edgeV1 + v1, intersectionPoint))
    {
        corners.push_back(intersectionPoint);
    }
    
    if (intersection(edgeV1, edgeV1 + v1, edgeV2, edgeV2 + v2, intersectionPoint))
    {
        corners.push_back(intersectionPoint);
    }
    
    if (intersection(edgeV2, edgeV2 + v2, edgeV3, edgeV3 + v3, intersectionPoint))
    {
        corners.push_back(intersectionPoint);
    }

    if (intersection(edgeV3, edgeV3 + v3, edgeV0, edgeV0 + v0, intersectionPoint))
    {
        corners.push_back(intersectionPoint);
    }
    
    return corners.size() == 4;
}
