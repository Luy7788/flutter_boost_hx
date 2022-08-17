//
//  HXFlutterViewContainer.m
//  flutter_boost
//
//  Created by Luy on 2022/8/5.
//

#import "HXFlutterViewContainer.h"

@interface HXFlutterViewContainer ()

@property (nonatomic, strong) UIImageView *_captureScreenView;
@property (nonatomic, strong) UIVisualEffectView *_visualEffectView;
@property (nonatomic, strong) UIScreenEdgePanGestureRecognizer *screenEdgePan;
@property (nonatomic, copy) swipeCallback _swipeCallback;
@property (nonatomic, assign) bool isPlatformView;
@property (nonatomic) CGRect platformViewRect;

@end

@implementation HXFlutterViewContainer

-(void)viewDidLoad {
    [super viewDidLoad];
}

-(void)viewWillDisappear:(BOOL)animated {
    
    //解决webview在页面切换出现的渲染问题
    if (self.isPlatformView == YES) {
        if (self._captureScreenView.image == nil) {
            [self _captureScreen];
        } else {
            [self.view addSubview:self._captureScreenView];
        }
    }
    if (self.disablePopGesture != nil) {
        if (self.navigationController != nil){
            self.navigationController.interactivePopGestureRecognizer.enabled = YES;
        }
    }
    if (self.screenEdgePan != nil) {
        [self.view removeGestureRecognizer:self.screenEdgePan];
        
    }
    [super viewWillDisappear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self._captureScreenView.image != nil && _isPlatformView == YES) {
        __weak __typeof(self)weakSelf = self;
        self.view.userInteractionEnabled = false;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf._captureScreenView removeFromSuperview];
            weakSelf._captureScreenView.image = nil;
            weakSelf.view.userInteractionEnabled = true;
        });
    }
}

- (void)setupPopGesture:(BOOL)enable {
    if (enable == true) {
        self.disablePopGesture = 0;
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    } else {
        self.disablePopGesture = @1;
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
}

- (void)setSwipeGestureListener:(swipeCallback)callback {
    if (self.screenEdgePan == nil) {
        self.screenEdgePan = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(_handleScreenEdgePan:)];
        self.screenEdgePan.edges = UIRectEdgeLeft;
    }
    [self.view addGestureRecognizer:self.screenEdgePan];
}

- (void)_handleScreenEdgePan:(UIScreenEdgePanGestureRecognizer *)edgePan {
    if (self._swipeCallback != nil) {
        CGPoint point = [edgePan translationInView:self.view];
        self._swipeCallback(point);
    }
}

- (void)_captureScreen {
    CGRect _viewRect = self.view.bounds;
    if (CGRectIsNull(self.platformViewRect) == NO) {
        _viewRect = self.platformViewRect;
    }
    UIImage *_image = [self imageFromView:self.view atFrame:_viewRect];
    if (_image != nil) {
        self._captureScreenView.image = _image;
        self._captureScreenView.frame = _viewRect;
        [self.view addSubview:self._captureScreenView];
    }
}

//获得某个范围内的屏幕图像
- (UIImage *)imageFromView:(UIView *)theView atFrame:(CGRect)rect {
    UIGraphicsBeginImageContextWithOptions(theView.frame.size, false, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    UIRectClip(rect);
    [theView.layer renderInContext:context];
    [[UIColor clearColor] setFill];
    UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();
//    CGImageRef cgImage = CGImageCreateWithImageInRect(theImage.CGImage, rect);
//    UIImage *returnImage = [UIImage imageWithCGImage:cgImage scale:[theImage scale] orientation:[theImage imageOrientation]];
//    CGImageRelease(cgImage);
//    UIGraphicsEndImageContext();
//    return returnImage;
    
    //获取 某图片 指定范围(rect)内的cgImage
    CGFloat (^rad)(CGFloat) = ^CGFloat(CGFloat deg) {
            return deg / 180.0f * (CGFloat) M_PI;
        };
    // determine the orientation of the image and apply a transformation to the crop rectangle to shift it to the correct position
    CGAffineTransform rectTransform;
    switch (theImage.imageOrientation) {
        case UIImageOrientationLeft:
            rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(rad(90)), 0, -theImage.size.height);
            break;
        case UIImageOrientationRight:
            rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(rad(-90)), -theImage.size.width, 0);
            break;
        case UIImageOrientationDown:
            rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(rad(-180)), -theImage.size.width, -theImage.size.height);
            break;
        default:
            rectTransform = CGAffineTransformIdentity;
    };
    // adjust the transformation scale based on the image scale
    rectTransform = CGAffineTransformScale(rectTransform, theImage.scale, theImage.scale);
    // apply the transformation to the rect to create a new, shifted rect
    CGRect transformedCropSquare = CGRectApplyAffineTransform(rect, rectTransform);
    // use the rect to crop the image
    CGImageRef imageRef = CGImageCreateWithImageInRect(theImage.CGImage, transformedCropSquare);
    // create a new UIImage and set the scale and orientation appropriately
    UIImage *result = [UIImage imageWithCGImage:imageRef scale:theImage.scale orientation:theImage.imageOrientation];
    // memory cleanup
    CGImageRelease(imageRef);
    return result;
}

- (void)enableEffect:(BOOL)isDark alpha:(CGFloat)alpha {
    if (self._visualEffectView == nil) {
        UIVisualEffect *blurEffect;
        if (isDark == YES) {
            blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        } else {
            blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        }
        UIVisualEffectView *_effectView = [[UIVisualEffectView alloc]initWithEffect:blurEffect];
        _effectView.frame = self.view.bounds;
        _effectView.alpha = alpha;
        self._visualEffectView = _effectView;
    }
    [self.view addSubview:self._visualEffectView];
}

- (void)disableEffect {
    [self._visualEffectView removeFromSuperview];
}

- (void)setupIsPlatformView:(BOOL)flag rect:(CGRect)rect {
    self.isPlatformView = flag;
    self.platformViewRect = rect;
    if (flag == NO && __captureScreenView != nil) {
        [self._captureScreenView removeFromSuperview];
        self._captureScreenView.image = nil;
    }
}

#pragma mark - 初始化
- (UIImageView *)_captureScreenView {
    if (__captureScreenView == nil) {
        __captureScreenView = [[UIImageView alloc] init];
        __captureScreenView.contentMode = UIViewContentModeScaleAspectFit;
        __captureScreenView.userInteractionEnabled = NO;
    }
    return __captureScreenView;
}

@end
