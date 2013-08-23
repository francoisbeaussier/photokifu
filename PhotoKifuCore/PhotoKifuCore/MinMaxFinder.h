//
//  MinMaxFinder.h
//  PhotoKifuCore
//
//  Created by Francois Beaussier on 13/06/13.
//  Copyright (c) 2013 Francois Beaussier. All rights reserved.
//

#ifndef __PhotoKifuCore__MinMaxFinder__
#define __PhotoKifuCore__MinMaxFinder__

#include <iostream>

template <class T> class MinMaxFinder
{
private:
    T _minX;
    T _minY;
    T _maxX;
    T _maxY;
    
public:
    MinMaxFinder()
    {
        _minX = _minY = std::numeric_limits<T>::max();
        _maxX = _maxY = std::numeric_limits<T>::min();
    }
    
    void CheckLines(const std::vector<std::vector<cv::Point>> &lines)
    {
        for (std::vector<std::vector<cv::Point>>::const_iterator it = lines.begin(); it != lines.end(); ++it)
        {
            CheckPoints(*it);
        }
    }

    void CheckPoints(const std::vector<cv::Point> &points)
    {
        for (std::vector<cv::Point>::const_iterator it = points.begin(); it != points.end(); ++it)
        {
            CheckPoint(*it);
        }
    }
    
    void CheckPoint(const cv::Point &p)
    {
        if (p.x < _minX)
        {
            _minX = p.x;
        }
        
        if (p.x > _maxX)
        {
            _maxX = p.x;
        }
        
        if (p.y < _minY)
        {
            _minY = p.y;
        }
        
        if (p.y > _maxY)
        {
            _maxY = p.y;
        }
    }

    std::vector<cv::Point> getMinMax()
    {
        std::vector<cv::Point> result;
        
        result.push_back(cv::Point(_minX, _minY));
        result.push_back(cv::Point(_maxX, _maxY));

        return result;
    }
};

#endif /* defined(__PhotoKifuCore__MinMaxFinder__) */
