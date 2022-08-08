//
//  HXFlutterViewContainer.h
//  flutter_boost
//
//  Created by Luy on 2022/8/5.
//

#import <Foundation/Foundation.h>
#import "FlutterBoost.h"
NS_ASSUME_NONNULL_BEGIN

typedef void(^swipeCallback)(UIScreenEdgePanGestureRecognizer *edgePan);

@interface HXFlutterViewContainer : FBFlutterViewContainer

@property (nonatomic, assign) bool isPresent;
@property (nonatomic, assign) bool isPlatformView;

- (void)setSwipeGestureListener:(swipeCallback)callback;

- (void)setupPopGesture:(BOOL)enable;

- (void)enableEffect:(BOOL)isDark result:(CGFloat)alpha;

- (void)disableEffect;
@end

NS_ASSUME_NONNULL_END
