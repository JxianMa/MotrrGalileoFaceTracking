//
//  ViewController.m
//  MotrrGalileoFaceTracking
//
//  Created by MaJixian on 7/13/15.
//  Copyright (c) 2015 MaJixian. All rights reserved.
//

#import "ViewController.h"
#import "DetectFace.h"
#import <GalileoControl/GalileoControl.h>


@interface ViewController () <DetectFaceDelegate,GCGalileoDelegate>

@property (weak, nonatomic) IBOutlet UIView *videoPreviewView;
@property (strong, nonatomic) DetectFace *detectFaceController;

@end

@implementation ViewController
{
    IBOutlet UIView *coordinateView;
    UIView *faceRectView;
    CGFloat screenWidth;
    CGFloat screenHeight;
    CGFloat faceRectCenterX;
    CGFloat faceRectCenterY;
    CGRect  faceRect;
    CGFloat xCoordinate;
    CGFloat yCoordinate;
    CGFloat distanceScale;
    NSTimer *positionCollectionTimer;
    UIView *currentPoint;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.detectFaceController = [[DetectFace alloc] init];
    self.detectFaceController.delegate = self;
    self.detectFaceController.previewView = self.videoPreviewView;
    faceRectView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 0, 0)];
    [self setupPortraitCoordinator];
    positionCollectionTimer = [NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(collectPosition) userInfo:nil repeats:YES];
    [GCGalileo sharedGalileo].delegate = self;
    [[GCGalileo sharedGalileo] waitForConnection];

}


- (void)setupPortraitCoordinator
{
    //Get screen width and screen height
    CGRect screenRect = [UIScreen mainScreen].bounds;
    screenWidth = screenRect.size.width;
    screenHeight = screenRect.size.height;
    
    //Setup Y axis
    UIView *Yaxis = [[UIView alloc]initWithFrame:CGRectMake(screenWidth/2, 0, 5, screenHeight)];
    [Yaxis setBackgroundColor:[UIColor whiteColor]];
    [self.view addSubview:Yaxis];
    
    //Setup X axis
    UIView *Xaxis = [[UIView alloc]initWithFrame:CGRectMake(0, screenHeight/2, screenWidth, 5)];
    [Xaxis setBackgroundColor:[UIColor whiteColor]];
    [self.view addSubview:Xaxis];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillUnload
{
    [self.detectFaceController stopDetection];
    [super viewWillUnload];
}

- (void)viewDidUnload {
    [self setVideoPreviewView:nil];
    [super viewDidUnload];
}

- (void)detectedFaceController:(DetectFace *)controller features:(NSArray *)featuresArray forVideoBox:(CGRect)clap withPreviewBox:(CGRect)previewBox
{
    for (CIFaceFeature *ff in featuresArray) {
        // find the correct position for the square layer within the previewLayer
        // the feature box originates in the bottom left of the video frame.
        // (Bottom right if mirroring is turned on)
        faceRect = [ff bounds];
        
        //isMirrored because we are using front camera
        faceRect = [DetectFace convertFrame:faceRect previewBox:previewBox forVideoBox:clap isMirrored:YES];
        faceRectCenterX = faceRect.origin.x + faceRect.size.width/2;
        faceRectCenterY = faceRect.origin.y + faceRect.size.height/2;
        //[faceRectView setFrame:faceRect];
        [faceRectView setFrame:CGRectMake(faceRectCenterX, faceRectCenterY, 10, 10)];
        [faceRectView setBackgroundColor:[UIColor redColor]];
        //xCoordinate = faceRectCenterX;
        yCoordinate = faceRectCenterY;
        [self.videoPreviewView addSubview:faceRectView];
        //NSLog(@"Face detected!");
        //NSLog(@"scale value for width:%f,height:%f",faceRect.size.width/screenWidth,faceRect.size.height/screenHeight);
        distanceScale = 0.2;
        [self convertViewCoordinateToGalileoCoordinate];
    }
}

- (void)convertViewCoordinateToGalileoCoordinate
{

        CGFloat xLocation = xCoordinate - screenWidth/2;
        NSLog(@"scale:%f",distanceScale);
        CGFloat galileoMovingAngleX = -(xLocation/(screenWidth/2))*90*distanceScale;
        [self moveGalileoToSpecificLocationWithXCoordinates:galileoMovingAngleX andYCoordinates:0];
        NSLog(@"galilieoMovingAngle:%f",galileoMovingAngleX);
}


- (void)moveGalileoToSpecificLocationWithXCoordinates:(CGFloat)x andYCoordinates:(CGFloat)y
{
    void (^completionBlock) (BOOL) = ^(BOOL wasCommandPreempted)
    {
        if (!wasCommandPreempted) [self controlDidReachTargetPosition];
    };
    [[[GCGalileo sharedGalileo] positionControlForAxis:GCControlAxisTilt] setTargetPosition:x completionBlock:completionBlock waitUntilStationary:YES];
}


#pragma mark -
#pragma mark PositionControl delegate

- (void) controlDidReachTargetPosition
{
    if ([[GCGalileo sharedGalileo] isConnected])
        NSLog(@"Galileo has arrived target position!");
}

- (void) galileoDidConnect
{
    NSLog(@"Galileo is connected.");
    //The default setting for proporty currentPosition is to set the position when Galileo is turned on
    [self.detectFaceController startDetection];
}

- (void) galileoDidDisconnect
{
    NSLog(@"Galileo is disconnected");
    [[GCGalileo sharedGalileo] waitForConnection];
}


- (void)collectPosition
{
    xCoordinate = faceRectCenterX;
}



@end
