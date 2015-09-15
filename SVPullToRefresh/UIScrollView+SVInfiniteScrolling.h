//
// UIScrollView+SVInfiniteScrolling.h
//
// Created by Sam Vermette on 23.04.12.
// Copyright (c) 2012 samvermette.com. All rights reserved.
//
// https://github.com/samvermette/SVPullToRefresh
//

#import <UIKit/UIKit.h>

@class SVInfiniteScrollingView;

typedef NS_ENUM(NSUInteger, SVInfiniteScrollingDirection) {
    SVInfiniteScrollingDirectionVertical = 0,
    SVInfiniteScrollingDirectionHorizontal = 1
};

typedef NS_ENUM(NSUInteger, SVInfiniteScrollingPosition) {
  SVInfiniteScrollingPositionTop,
  SVInfiniteScrollingPositionBottom
};

@interface UIScrollView (SVInfiniteScrolling)

- (void)addInfiniteScrollingWithActionHandler:(void (^)(void))actionHandler;
- (void)addInfiniteScrollingWithActionHandler:(void (^)(void))actionHandler direction:(SVInfiniteScrollingDirection)direction;
- (void)addInfiniteScrollingWithActionHandler:(void (^)(void))actionHandler direction:(SVInfiniteScrollingDirection)direction position:(SVInfiniteScrollingPosition)position;
- (void)triggerInfiniteScrollingTop;
- (void)triggerInfiniteScrollingBottom;

@property (nonatomic, strong, readonly) SVInfiniteScrollingView *infiniteScrollingView;
@property (nonatomic, strong, readonly) SVInfiniteScrollingView *infiniteScrollingViewTop;
@property (nonatomic, strong, readonly) SVInfiniteScrollingView *infiniteScrollingViewBottom;
@property (nonatomic, assign) BOOL showsInfiniteScrollingTop;
@property (nonatomic, assign) BOOL showsInfiniteScrollingBottom;

@end


enum {
	SVInfiniteScrollingStateStopped = 0,
    SVInfiniteScrollingStateTriggered,
    SVInfiniteScrollingStateLoading,
    SVInfiniteScrollingStateAll = 10
};

typedef NSUInteger SVInfiniteScrollingState;

@interface SVInfiniteScrollingView : UIView

@property (nonatomic, readwrite) UIActivityIndicatorViewStyle activityIndicatorViewStyle;
@property (nonatomic, readonly) SVInfiniteScrollingState state;
@property (nonatomic, readwrite) BOOL enabled;
@property (nonatomic, readwrite) CGFloat originalBottomInset;
@property (nonatomic, readwrite) CGFloat originalRightInset;

- (void)setCustomView:(UIView *)view forState:(SVInfiniteScrollingState)state;

- (void)startAnimating;
- (void)stopAnimating;

@end
