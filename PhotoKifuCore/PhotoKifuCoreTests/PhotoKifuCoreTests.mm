//
//  PhotoKifuCoreTests.m
//  PhotoKifuCoreTests
//
//  Created by Francois Beaussier on 9/04/13.
//  Copyright (c) 2013 Francois Beaussier. All rights reserved.
//

#import "PhotoKifuCoreTests.h"
#import "PhotoKifuCore.h"
#import "TestImageData.h"

@implementation PhotoKifuCoreTests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void) createOrEmptyDirectory: (NSString *) dir
{
    NSFileManager *fileManager= [NSFileManager defaultManager];
    
    if (![fileManager fileExistsAtPath: dir])
    {
        if (![fileManager createDirectoryAtPath: dir withIntermediateDirectories: YES attributes: nil error: NULL])
        {
            NSLog(@"Error: Create folder failed %@", dir);
            
            STFail(@"Could not create output folder");
        }
    }
    
    NSArray *fileArray = [fileManager contentsOfDirectoryAtPath: dir error: nil];
    
    for (NSString *filename in fileArray)
    {
        [fileManager removeItemAtPath: [dir stringByAppendingPathComponent: filename] error: NULL];
    }
}

- (void) writeImage: (cv::Mat&) mat toFile:(NSString *) filename
{
    //const int INTER_LANCZOS4 = 4;
    
//    resize(mat, mat, cv::Size(640 * 3, 480 * 3), 0, 0, INTER_LANCZOS4);
    
    UIImage *image = [PhotoKifuCore UIImageFromCVMat: mat];
    
    [UIImagePNGRepresentation(image) writeToFile: filename atomically: YES];
}

- (UIImage *) loadImage:(NSString *)imageFile
{
    NSString *imagePath = [[NSBundle bundleForClass: [self class]] pathForResource: imageFile ofType: nil];
    UIImage *image = [UIImage imageWithContentsOfFile: imagePath];
    
    NSAssert(image, @"image is nil. Check the bundle.");
    
    return image;
}

- (NSArray *) loadTestImages
{
    NSArray *imageFiles = [NSArray arrayWithObjects:
                           @"photo.jpg",
                           @"photo_1.jpg",
                           @"photo_2.jpg",
                           @"photo_3.jpg",
                           @"photo_4.jpg",
                           @"photo_5.jpg",
                           @"photo_6.jpg",
                           nil];
    
    NSMutableArray *images = [NSMutableArray array];
    
    for (NSString *imageFile in imageFiles)
    {
        [images addObject: [self loadImage: imageFile]];
    }
    
    return images;
}

- (NSArray *) loadTestImagesWithCornerCoordinates
{
    NSArray *images = [NSArray arrayWithObjects:
                       [[TestImageData alloc] initWithImage: [self loadImage:@"photo.jpg"] andCoordinates:CGPointMake(919, 367) :CGPointMake(2605, 374) :CGPointMake(2709, 1963) :CGPointMake(880, 1998)],
                       [[TestImageData alloc] initWithImage: [self loadImage:@"photo_1.jpg"] andCoordinates:CGPointMake(880, 477) :CGPointMake(2549, 526) :CGPointMake(2594, 2111) :CGPointMake(793, 2094)],
                       [[TestImageData alloc] initWithImage: [self loadImage:@"photo_2.jpg"] andCoordinates:CGPointMake(864, 1022) :CGPointMake(1740, 640) :CGPointMake(2512, 1288) :CGPointMake(1562, 1898)],
                       [[TestImageData alloc] initWithImage: [self loadImage:@"photo_3.jpg"] andCoordinates:CGPointMake(730, 788) :CGPointMake(1846, 810) :CGPointMake(1830, 1886) :CGPointMake(736, 1892)],
                       nil];
    
    return images;
}

- (void) _testPhotoKifuGobanDetection
{
    NSString *libraryPath = [[NSString alloc] initWithString: [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, TRUE) objectAtIndex:0]];
    
    NSString *outputPath = [libraryPath stringByAppendingPathComponent: @"PhotoKifuCoreTests"];
    
    [self createOrEmptyDirectory: outputPath];
    
    NSArray *images = [self loadTestImages];

    cv::vector<cv::vector<std::pair<const cv::Mat, const char *>>> debugImages;

    for (UIImage *image in images)
    {
        GobanDetector gb(true);
        
        cv::vector<cv::Point> corners;
                
        cv::vector<cv::Point> contour = gb.detectGoban(image);
        
        debugImages.push_back(gb.getDebugImages());
    }
    
    [self outputTestResult:debugImages atPath:outputPath];
}

- (void) testPhotoKifuGobanExtraction
{
    NSString *libraryPath = [[NSString alloc] initWithString: [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, TRUE) objectAtIndex:0]];
    
    NSString *outputPath = [libraryPath stringByAppendingPathComponent: @"PhotoKifuCoreTests"];
    
    [self createOrEmptyDirectory: outputPath];
    
    NSArray *images = [self loadTestImagesWithCornerCoordinates];
    
    cv::vector<cv::vector<std::pair<const cv::Mat, const char *>>> debugImages;
    
    for (TestImageData *imageData in images)
    {
        GobanDetector gb(true);
        
        cv::vector<cv::Point> corners;
        
        corners.push_back(cv::Point(imageData.a.x, imageData.a.y));
        corners.push_back(cv::Point(imageData.b.x, imageData.b.y));
        corners.push_back(cv::Point(imageData.c.x, imageData.c.y));
        corners.push_back(cv::Point(imageData.d.x, imageData.d.y));
        
        cv::vector<cv::vector<cv::Point>> stones = gb.extractGobanState(imageData.image, corners);
        
        debugImages.push_back(gb.getDebugImages());
    }
    
    [self outputTestResult:debugImages atPath:outputPath];
}

- (void) testPhotoKifuCoreStoneDetection
{
    NSString *libraryPath = [[NSString alloc] initWithString: [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, TRUE) objectAtIndex:0]];

    NSString *outputPath = [libraryPath stringByAppendingPathComponent: @"PhotoKifuCoreTests"];
    
    [self createOrEmptyDirectory: outputPath];
    
    NSArray *imageFiles = [NSArray arrayWithObjects:
                           //@"photo.jpg",
                           //@"photo_1.jpg",
                           @"photo_2.jpg",
                           //@"photo_3.jpg",
                           //@"photo_4.jpg",
                           //@"photo_5.jpg",
                           //@"photo_6.jpg",
                           nil];
    
    cv::vector<cv::vector<std::pair<const cv::Mat, const char *>>> debugImages;
    
    int srcImageId = 0;

    for (NSString *imageFile in imageFiles)
    {
        
        NSString *imagePath = [[NSBundle bundleForClass: [self class]] pathForResource: imageFile ofType: nil];
        UIImage *image = [UIImage imageWithContentsOfFile: imagePath];
        
        NSAssert(image, @"image is nil. Check the bundle.");

        // image = [PhotoKifuCore imageWithImage: image scaledToSize: CGSizeMake(800, 600)];
        
        GobanDetector gb(true);
        
        cv::vector<cv::Point> corners;
        
        corners = gb.detectGoban(image);
        
        cv::vector<cv::vector<cv::Point>> stones;
        
        if (stones.size() == 2)
        {
            NSString *sgf = [PhotoKifuCore generateSgfContent: stones];
            
            // NSString *sgf = [NSString stringWithCString: sgfRaw encoding: NSUTF8StringEncoding];
            
            NSLog(@"sgf (%@): %@", imageFile, sgf);
            
            NSString *filepath = [[NSString alloc] initWithFormat:@"%@/%@%i%@", outputPath, @"result-", srcImageId, @".sgf"];
            
            NSError *error = nil;
            [sgf writeToFile: filepath atomically: YES encoding: NSUTF8StringEncoding error: &error];
            
            if (error)
            {
                NSLog(@"%@", [error localizedDescription]);
                
                STFail (@"Could not write the sgf file");
            }
        }
        
        debugImages.push_back(gb.getDebugImages());
        
        srcImageId++;
    }
}

- (void) outputTestResult:(cv::vector<cv::vector<std::pair<const cv::Mat, const char *>>>)debugImages atPath:(NSString *)outputPath
{
    int htmlImageDisplayMargin = 5;
    int htmlImageDisplayWidth = 640;
    int htmlImageDisplayHeight = 480;
    int pageBodyWidth = debugImages.size() * (htmlImageDisplayWidth + htmlImageDisplayMargin * 2);
    
    NSMutableString *html = [[NSMutableString alloc] initWithFormat: @"<html><body style=\"width: %ipx\">\n", pageBodyWidth];
    
    int imageId = 0;
    int columnId = 0;
    
    for (cv::vector<cv::vector<std::pair<const cv::Mat, const char *>>>::iterator it = debugImages.begin(); it != debugImages.end(); ++it, imageId++)
    {
        [html appendString: @"<div style=\"float: left\">\n"];
        
        for (cv::vector<std::pair<const cv::Mat, const char *>>::iterator it2 = it->begin(); it2 != it->end(); ++it2, imageId++)
        {
            std::pair<const cv::Mat, const char *> data = *it2;
            
            NSString *filename = [outputPath stringByAppendingFormat: @"/img_%i.png", imageId];
            
            cv::Mat image = data.first;
            const char* description = data.second;
            
            [self writeImage: image toFile: filename];
            
            if (description != NULL)
            {
                [html appendFormat: @"<p style=\"float: left; margin: 2px; clear: left\"/>%s</p>\n", description];
            }
            
            [html appendFormat: @"<img src=\"img_%i.png\" width=\"%ipx\" height=\"%ipx\" style=\"float: left; margin: %ipx; clear: left\"/>\n", imageId, htmlImageDisplayWidth, htmlImageDisplayHeight, htmlImageDisplayMargin];
        }

        NSString *resultFile = [[NSString alloc] initWithFormat:@"%@%i%@", @"result-", columnId, @".sgf"];
        
        [html appendFormat: @"<br/> <a href=\"%@\" download=\"%@\" style=\"float: left; margin: 2px; clear: left\">View result</a>\n", resultFile, resultFile];

        [html appendString: @"</div>\n"];
        
        columnId++;
    }
    
    [html appendString: @"</body></html>\n"];
    
    NSString *filepath = [[NSString alloc] initWithFormat:@"%@/%@", outputPath, @"output.html"];
    
    NSError *error = nil;
    [html writeToFile: filepath atomically: YES encoding: NSUTF8StringEncoding error: &error];
    
    if (error)
    {
        NSLog(@"%@", [error localizedDescription]);
        
        STFail (@"Could not write the html file");
    }
    
}

@end
