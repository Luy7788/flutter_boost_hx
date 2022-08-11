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
    
    if (self.disablePopGesture != nil) {
        if (self.navigationController != nil){
            self.navigationController.interactivePopGestureRecognizer.enabled = YES;
        }
    }
    if (self.screenEdgePan != nil) {
        [self.view removeGestureRecognizer:self.screenEdgePan];
        
    }
    //解决webview在页面切换出现的渲染问题
    if (self._captureScreenView.image == nil && self.isPlatformView == YES) {
        [self _captureScreen];
    }
    [super viewWillDisappear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self._captureScreenView.image != nil && _isPlatformView == YES) {
        __weak __typeof(self)weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf._captureScreenView removeFromSuperview];
            weakSelf._captureScreenView.image = nil;
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
//    UIGraphicsBeginImageContextWithOptions(_viewRect.size, false, 0);
//    CGContextRef _ctx = UIGraphicsGetCurrentContext();
//    if (_ctx != nil) {
//        [self.view.layer renderInContext:_ctx];
//        UIImage *_image = UIGraphicsGetImageFromCurrentImageContext();
//        self._captureScreenView.image = _image;
//        self._captureScreenView.frame = CGRectMake(0, 0, _viewRect.size.width, _viewRect.size.height);
//        [self.view addSubview:self._captureScreenView];
//    }
//    UIGraphicsEndImageContext();
    UIImage *_image = [self imageFromView:self.view atFrame:_viewRect];
    if (_image != nil) {
        self._captureScreenView.image = _image;
        self._captureScreenView.frame = _viewRect;
        [self.view addSubview:self._captureScreenView];
    }
}

//获得某个范围内的屏幕图像

- (UIImage *)imageFromView:(UIView *)theView atFrame:(CGRect)rect {
    UIGraphicsBeginImageContext(theView.frame.size);
    //用这个不会失真
//    UIGraphicsBeginImageContextWithOptions(theView.frame.size, false, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    //这里其实就是裁剪
    UIRectClip(rect);
    [theView.layer renderInContext:context];
    //设定颜色：透明
    [[UIColor clearColor] setFill];
    UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();
    //获取 某图片 指定范围(rect)内的cgImage
    CGImageRef cgImage = CGImageCreateWithImageInRect(theImage.CGImage, rect);
    UIImage * returnImage = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    UIGraphicsEndImageContext();
    return returnImage;
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
