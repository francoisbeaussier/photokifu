//
//  GobanView.h
//  PhotoKifu2
//
//  Created by Francois Beaussier on 11/07/13.
//  Copyright (c) 2013 Francois Beaussier. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GobanView : UIView
{
    int _gobanSize;
    float _gridCellWidth;
    float _gridLeftPadding;

#ifdef __cplusplus
    cv::vector<cv::vector<cv::Point>> _stones;
#endif

}

#ifdef __cplusplus
- (void) setStones: (cv::vector<cv::vector<cv::Point>>) stones;
#endif


@end
