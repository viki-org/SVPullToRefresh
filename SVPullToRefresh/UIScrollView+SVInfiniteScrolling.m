//
// UIScrollView+SVInfiniteScrolling.m
//
// Created by Sam Vermette on 23.04.12.
// Copyright (c) 2012 samvermette.com. All rights reserved.
//
// https://github.com/samvermette/SVPullToRefresh
//

#import <QuartzCore/QuartzCore.h>
#import "UIScrollView+SVInfiniteScrolling.h"


static CGFloat const SVInfiniteScrollingViewWidth = 60;
static CGFloat const SVInfiniteScrollingViewHeight = 60;

@interface SVInfiniteScrollingDotView : UIView

@property (nonatomic, strong) UIColor *arrowColor;

@end



@interface SVInfiniteScrollingView ()

@property (nonatomic, copy) void (^infiniteScrollingHandler)(void);

@property (nonatomic, readwrite) SVInfiniteScrollingDirection direction;
@property (nonatomic, readwrite) SVInfiniteScrollingPosition position;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic, readwrite) SVInfiniteScrollingState state;
@property (nonatomic, strong) NSMutableArray *viewForState;
@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, readwrite) CGFloat originalBottomInset;
@property (nonatomic, readwrite) CGFloat originalRightInset;
@property (nonatomic, readwrite) CGFloat originalTopInset;
@property (nonatomic, readwrite) CGFloat originalLeftInset;
@property (nonatomic, assign) BOOL wasTriggeredByUser;
@property (nonatomic, assign) BOOL isObserving;

- (void)resetScrollViewContentInset;
- (void)setScrollViewContentInsetForInfiniteScrolling;
- (void)setScrollViewContentInset:(UIEdgeInsets)insets;

@end



#pragma mark - UIScrollView (SVInfiniteScrollingView)
#import <objc/runtime.h>

static char UIScrollViewInfiniteScrollingViewTop;
static char UIScrollViewInfiniteScrollingViewBottom;
UIEdgeInsets scrollViewOriginalContentInsets;

@implementation UIScrollView (SVInfiniteScrolling)

@dynamic infiniteScrollingViewTop;
@dynamic infiniteScrollingViewBottom;

- (void)addInfiniteScrollingWithActionHandler:(void (^)(void))actionHandler {
  [self addInfiniteScrollingWithActionHandler:actionHandler direction:SVInfiniteScrollingDirectionVertical position:SVInfiniteScrollingPositionBottom];
}

- (void)addInfiniteScrollingWithActionHandler:(void (^)(void))actionHandler direction:(SVInfiniteScrollingDirection)direction {
  [self addInfiniteScrollingWithActionHandler:actionHandler direction:direction position:SVInfiniteScrollingPositionBottom];
}

- (void)addInfiniteScrollingWithActionHandler:(void (^)(void))actionHandler direction:(SVInfiniteScrollingDirection)direction position:(SVInfiniteScrollingPosition)position {
  switch (position) {
    case SVInfiniteScrollingPositionTop:
      if(!self.infiniteScrollingViewTop) {
        CGRect frame = CGRectZero;
        if (direction == SVInfiniteScrollingDirectionVertical) {
          frame = CGRectMake(0, 0 - SVInfiniteScrollingViewHeight, self.bounds.size.width, SVInfiniteScrollingViewHeight);
        } else {
          frame = CGRectMake(0 - SVInfiniteScrollingViewWidth, (self.bounds.size.height - SVInfiniteScrollingViewWidth) / 2, SVInfiniteScrollingViewWidth, SVInfiniteScrollingViewHeight);
        }
        SVInfiniteScrollingView *view = [[SVInfiniteScrollingView alloc] initWithFrame:frame];
        view.infiniteScrollingHandler = actionHandler;
        view.scrollView = self;
        view.direction = direction;
        view.position = position;
        view.backgroundColor = [UIColor yellowColor];
        [self addSubview:view];
        
        view.originalTopInset = self.contentInset.top;
        view.originalLeftInset = self.contentInset.left;
        self.infiniteScrollingViewTop = view;
        self.showsInfiniteScrollingTop = YES;
      }
      break;
      
    case SVInfiniteScrollingPositionBottom:
      if(!self.infiniteScrollingViewBottom) {
        CGRect frame = CGRectZero;
        if (direction == SVInfiniteScrollingDirectionVertical) {
          frame = CGRectMake(0, self.contentSize.height, self.bounds.size.width, SVInfiniteScrollingViewHeight);
        } else {
          frame = CGRectMake(self.contentSize.width, (self.bounds.size.height - SVInfiniteScrollingViewWidth) / 2, SVInfiniteScrollingViewWidth, SVInfiniteScrollingViewHeight);
        }
        SVInfiniteScrollingView *view = [[SVInfiniteScrollingView alloc] initWithFrame:frame];
        view.infiniteScrollingHandler = actionHandler;
        view.scrollView = self;
        view.direction = direction;
        view.position = position;
        view.backgroundColor = [UIColor orangeColor];
        [self addSubview:view];
        
        view.originalBottomInset = self.contentInset.bottom;
        view.originalRightInset = self.contentInset.right;
        self.infiniteScrollingViewBottom = view;
        self.showsInfiniteScrollingBottom = YES;
      }
      break;
  }
}

- (void)triggerInfiniteScrollingTop {
  self.infiniteScrollingViewTop.state = SVInfiniteScrollingStateTriggered;
  [self.infiniteScrollingViewTop startAnimating];
}

- (void)triggerInfiniteScrollingBottom {
  self.infiniteScrollingViewBottom.state = SVInfiniteScrollingStateTriggered;
  [self.infiniteScrollingViewBottom startAnimating];
}

- (void)setInfiniteScrollingViewTop:(SVInfiniteScrollingView *)infiniteScrollingView {
  [self willChangeValueForKey:@"UIScrollViewInfiniteScrollingViewTop"];
  objc_setAssociatedObject(self, &UIScrollViewInfiniteScrollingViewTop,
                           infiniteScrollingView,
                           OBJC_ASSOCIATION_ASSIGN);
  [self didChangeValueForKey:@"UIScrollViewInfiniteScrollingViewTop"];
}

- (void)setInfiniteScrollingViewBottom:(SVInfiniteScrollingView *)infiniteScrollingView {
  [self willChangeValueForKey:@"UIScrollViewInfiniteScrollingViewBottom"];
  objc_setAssociatedObject(self, &UIScrollViewInfiniteScrollingViewBottom,
                           infiniteScrollingView,
                           OBJC_ASSOCIATION_ASSIGN);
  [self didChangeValueForKey:@"UIScrollViewInfiniteScrollingViewBottom"];
}


- (SVInfiniteScrollingView *)infiniteScrollingViewTop {
  return objc_getAssociatedObject(self, &UIScrollViewInfiniteScrollingViewTop);
}

- (SVInfiniteScrollingView *)infiniteScrollingViewBottom {
  return objc_getAssociatedObject(self, &UIScrollViewInfiniteScrollingViewBottom);
}

- (void)setShowsInfiniteScrollingTop:(BOOL)showsInfiniteScrollingTop {
  self.infiniteScrollingViewTop.hidden = !showsInfiniteScrollingTop;
  if(!showsInfiniteScrollingTop) {
    if (self.infiniteScrollingViewTop.isObserving) {
      [self stopObservingForInfiniteScrollingView:self.infiniteScrollingViewTop];
    }
  } else {
    if (!self.infiniteScrollingViewTop.isObserving) {
      [self startObservingForInfiniteScrollingView:self.infiniteScrollingViewTop];
    }
  }
}

- (void)setShowsInfiniteScrollingBottom:(BOOL)showsInfiniteScrollingBottom {
  self.infiniteScrollingViewBottom.hidden = !showsInfiniteScrollingBottom;
  if (!showsInfiniteScrollingBottom) {
    if (self.infiniteScrollingViewBottom.isObserving) {
      [self stopObservingForInfiniteScrollingView:self.infiniteScrollingViewBottom];
    }
  } else {
    if (!self.infiniteScrollingViewBottom.isObserving) {
      [self startObservingForInfiniteScrollingView:self.infiniteScrollingViewBottom];
    }
  }

}

- (void)stopObservingForInfiniteScrollingView:(SVInfiniteScrollingView *)scrollingView {
  if (scrollingView) {
    [self removeObserver:scrollingView forKeyPath:@"contentOffset"];
    [self removeObserver:scrollingView forKeyPath:@"contentSize"];
    
    [scrollingView resetScrollViewContentInset];
    scrollingView.isObserving = NO;
  }
}

- (void)startObservingForInfiniteScrollingView:(SVInfiniteScrollingView *)scrollingView {
  if (scrollingView) {
    [self addObserver:scrollingView forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
    [self addObserver:scrollingView forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:nil];
//    [scrollingView setScrollViewContentInsetForInfiniteScrolling];
    scrollingView.isObserving = YES;
    
    [scrollingView setNeedsLayout];
    if (scrollingView.direction == SVInfiniteScrollingDirectionVertical) {
      if (scrollingView.position == SVInfiniteScrollingPositionTop) {
        scrollingView.frame = CGRectMake(0, 0 - SVInfiniteScrollingViewHeight, scrollingView.bounds.size.width, SVInfiniteScrollingViewHeight);
      } else {
        scrollingView.frame = CGRectMake(0, self.contentSize.height, scrollingView.bounds.size.width, SVInfiniteScrollingViewHeight);
      }
    } else if (scrollingView.direction == SVInfiniteScrollingDirectionHorizontal) {
      if (scrollingView.position == SVInfiniteScrollingPositionTop) {
        scrollingView.frame = CGRectMake(0 - SVInfiniteScrollingViewWidth, (self.contentSize.height - SVInfiniteScrollingViewHeight) / 2, SVInfiniteScrollingViewWidth, SVInfiniteScrollingViewHeight);
      } else {
        scrollingView.frame = CGRectMake(self.contentSize.width, (self.contentSize.height - SVInfiniteScrollingViewHeight) / 2, SVInfiniteScrollingViewWidth, SVInfiniteScrollingViewHeight);
      }
    }
  }
}

- (BOOL)showsInfiniteScrollingTop {
  return !self.infiniteScrollingViewTop.hidden;
}

- (BOOL)showsInfiniteScrollingBottom {
  return !self.infiniteScrollingViewBottom.hidden;
}

@end


#pragma mark - SVInfiniteScrollingView
@implementation SVInfiniteScrollingView

// public properties
@synthesize infiniteScrollingHandler, activityIndicatorViewStyle;

@synthesize state = _state;
@synthesize scrollView = _scrollView;
@synthesize activityIndicatorView = _activityIndicatorView;

- (id)initWithFrame:(CGRect)frame {
  if(self = [super initWithFrame:frame]) {
    
    // default styling values
    self.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    if (self.direction == SVInfiniteScrollingDirectionVertical)
      self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    else if (self.direction == SVInfiniteScrollingDirectionHorizontal)
      self.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    self.state = SVInfiniteScrollingStateStopped;
    self.enabled = YES;
    
    self.viewForState = [NSMutableArray arrayWithObjects:@"", @"", @"", @"", nil];
  }
  
  return self;
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
  if (self.superview && newSuperview == nil) {
    UIScrollView *scrollView = (UIScrollView *)self.superview;    if ((self.position == SVInfiniteScrollingPositionTop && scrollView.showsInfiniteScrollingTop) || (self.position == SVInfiniteScrollingPositionBottom && scrollView.showsInfiniteScrollingBottom)) {
      if (self.isObserving) {
        [scrollView removeObserver:self forKeyPath:@"contentOffset"];
        [scrollView removeObserver:self forKeyPath:@"contentSize"];
        self.isObserving = NO;
      }
    }
  }
}

- (void)layoutSubviews {
  self.activityIndicatorView.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
}

#pragma mark - Scroll View

- (void)resetScrollViewContentInset {
  UIEdgeInsets currentInsets = self.scrollView.contentInset;
  if (self.direction == SVInfiniteScrollingDirectionVertical) {
    if (self.position == SVInfiniteScrollingPositionTop) {
      currentInsets.top = self.originalTopInset;
    } else {
      currentInsets.bottom = self.originalBottomInset;
    }
  } else if (self.direction == SVInfiniteScrollingDirectionHorizontal) {
    if (self.position == SVInfiniteScrollingPositionTop) {
      currentInsets.left = self.originalLeftInset;
    } else {
      currentInsets.right = self.originalRightInset;
    }
  }
  [self setScrollViewContentInset:currentInsets];
}

- (void)setScrollViewContentInsetForInfiniteScrolling {
  UIEdgeInsets currentInsets = self.scrollView.contentInset;
  if (self.direction == SVInfiniteScrollingDirectionVertical) {
    if (self.position == SVInfiniteScrollingPositionTop) {
      currentInsets.top = self.originalTopInset + SVInfiniteScrollingViewHeight;
    } else {
      currentInsets.bottom = self.originalBottomInset + SVInfiniteScrollingViewHeight;
    }
  } else if (self.direction == SVInfiniteScrollingDirectionHorizontal) {
    if (self.position == SVInfiniteScrollingPositionTop) {
      currentInsets.left = self.originalLeftInset + SVInfiniteScrollingViewWidth;
    } else {
      currentInsets.right = self.originalRightInset + SVInfiniteScrollingViewWidth;
    }
  }
  
  [self setScrollViewContentInset:currentInsets];
}

- (void)setScrollViewContentInset:(UIEdgeInsets)contentInset {
  [UIView animateWithDuration:0.3
                        delay:0
                      options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState
                   animations:^{
                     self.scrollView.contentInset = contentInset;                   }
                   completion:^(BOOL complete) {
                   }];

}

- (void)setScrollViewContentInset:(UIEdgeInsets)contentInset contentOffset:(CGPoint)contentOffset {
  [UIView animateWithDuration:0.3
                        delay:0
                      options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState
                   animations:^{
                     self.scrollView.contentInset = contentInset;
                     self.scrollView.contentOffset = contentOffset;
                   }
                   completion:^(BOOL complete) {
                     self.scrollView.contentOffset = contentOffset;
                   }];
}

#pragma mark - Observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  if([keyPath isEqualToString:@"contentOffset"])
    [self scrollViewDidScroll:[[change valueForKey:NSKeyValueChangeNewKey] CGPointValue]];
  else if([keyPath isEqualToString:@"contentSize"]) {
    [self layoutSubviews];
    if (self.direction == SVInfiniteScrollingDirectionVertical) {
      if (self.position == SVInfiniteScrollingPositionTop) {
        self.frame = CGRectMake(0, 0 - SVInfiniteScrollingViewHeight, self.bounds.size.width, SVInfiniteScrollingViewHeight);
      } else {
        self.frame = CGRectMake(0, self.scrollView.contentSize.height, self.bounds.size.width, SVInfiniteScrollingViewHeight);
      }
    } else if (self.direction == SVInfiniteScrollingDirectionHorizontal) {
      if (self.position == SVInfiniteScrollingPositionTop) {
        self.frame = CGRectMake(0 - SVInfiniteScrollingViewWidth, (self.scrollView.contentSize.height - SVInfiniteScrollingViewWidth) / 2, SVInfiniteScrollingViewWidth, SVInfiniteScrollingViewHeight);
      } else {
        self.frame = CGRectMake(self.scrollView.contentSize.width, (self.scrollView.contentSize.height - SVInfiniteScrollingViewHeight) / 2, SVInfiniteScrollingViewWidth, SVInfiniteScrollingViewHeight);
      }
    }
  }
}

- (void)scrollViewDidScroll:(CGPoint)contentOffset {
  if(self.state != SVInfiniteScrollingStateLoading && self.enabled) {
    if (self.direction == SVInfiniteScrollingDirectionVertical)
    {
      if (self.position == SVInfiniteScrollingPositionTop) {
        if(!self.scrollView.isDragging && self.state == SVInfiniteScrollingStateTriggered) {
          self.state = SVInfiniteScrollingStateLoading;
        }
        else if (contentOffset.y < 0 && self.state == SVInfiniteScrollingStateStopped && self.scrollView.isDragging)
          self.state = SVInfiniteScrollingStateTriggered;
        else if (contentOffset.y >= 0 && self.state != SVInfiniteScrollingStateStopped) {
          self.state = SVInfiniteScrollingStateStopped;
        }

        
      } else {
        CGFloat scrollViewContentHeight = self.scrollView.contentSize.height;
        CGFloat scrollOffsetThreshold = scrollViewContentHeight-self.scrollView.bounds.size.height;
        
        if(!self.scrollView.isDragging && self.state == SVInfiniteScrollingStateTriggered) {
          self.state = SVInfiniteScrollingStateLoading;        }
        else if (contentOffset.y > scrollOffsetThreshold && self.state == SVInfiniteScrollingStateStopped && self.scrollView.isDragging)
          self.state = SVInfiniteScrollingStateTriggered;
        else if (contentOffset.y < scrollOffsetThreshold && self.state != SVInfiniteScrollingStateStopped) {
          self.state = SVInfiniteScrollingStateStopped;        }
      }
    }
    else if (self.direction == SVInfiniteScrollingDirectionHorizontal)
    {
      CGFloat scrollViewContentWidth = self.scrollView.contentSize.width;
      CGFloat scrollOffsetThreshold = scrollViewContentWidth-self.scrollView.bounds.size.width;
      
      if(!self.scrollView.isDragging && self.state == SVInfiniteScrollingStateTriggered)
        self.state = SVInfiniteScrollingStateLoading;
      else if(contentOffset.x > scrollOffsetThreshold && self.state == SVInfiniteScrollingStateStopped && self.scrollView.isDragging)
        self.state = SVInfiniteScrollingStateTriggered;
      else if(contentOffset.x < scrollOffsetThreshold  && self.state != SVInfiniteScrollingStateStopped)
        self.state = SVInfiniteScrollingStateStopped;
    }
  }
}

#pragma mark - Getters

- (UIActivityIndicatorView *)activityIndicatorView {
  if(!_activityIndicatorView) {
    _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    _activityIndicatorView.hidesWhenStopped = YES;
    [self addSubview:_activityIndicatorView];
  }
  return _activityIndicatorView;
}

- (UIActivityIndicatorViewStyle)activityIndicatorViewStyle {
  return self.activityIndicatorView.activityIndicatorViewStyle;
}

#pragma mark - Setters

- (void)setCustomView:(UIView *)view forState:(SVInfiniteScrollingState)state {
  id viewPlaceholder = view;
  
  if(!viewPlaceholder)
    viewPlaceholder = @"";
  
  if(state == SVInfiniteScrollingStateAll)
    [self.viewForState replaceObjectsInRange:NSMakeRange(0, 3) withObjectsFromArray:@[viewPlaceholder, viewPlaceholder, viewPlaceholder]];
  else
    [self.viewForState replaceObjectAtIndex:state withObject:viewPlaceholder];
  
  self.state = self.state;
}

- (void)setActivityIndicatorViewStyle:(UIActivityIndicatorViewStyle)viewStyle {
  self.activityIndicatorView.activityIndicatorViewStyle = viewStyle;
}

#pragma mark -

- (void)triggerRefresh {
  self.state = SVInfiniteScrollingStateTriggered;
  self.state = SVInfiniteScrollingStateLoading;
}

- (void)startAnimating{
  self.state = SVInfiniteScrollingStateLoading;
}

- (void)stopAnimating {
  self.state = SVInfiniteScrollingStateStopped;
}

- (void)setState:(SVInfiniteScrollingState)newState {
  
  if(_state == newState)
    return;
  
  SVInfiniteScrollingState previousState = _state;
  _state = newState;
  
  for(id otherView in self.viewForState) {
    if([otherView isKindOfClass:[UIView class]])
      [otherView removeFromSuperview];
  }
  
  id customView = [self.viewForState objectAtIndex:newState];
  BOOL hasCustomView = [customView isKindOfClass:[UIView class]];
  
  if(hasCustomView) {
    [self addSubview:customView];
    CGRect viewBounds = [customView bounds];
    CGPoint origin = CGPointMake(roundf((self.bounds.size.width-viewBounds.size.width)/2), roundf((self.bounds.size.height-viewBounds.size.height)/2));
    [customView setFrame:CGRectMake(origin.x, origin.y, viewBounds.size.width, viewBounds.size.height)];
  }
  else {
    CGRect viewBounds = [self.activityIndicatorView bounds];
    CGPoint origin = CGPointMake(roundf((self.bounds.size.width-viewBounds.size.width)/2), roundf((self.bounds.size.height-viewBounds.size.height)/2));
    [self.activityIndicatorView setFrame:CGRectMake(origin.x, origin.y, viewBounds.size.width, viewBounds.size.height)];
    
    switch (newState) {
      case SVInfiniteScrollingStateStopped: {
        [self.activityIndicatorView stopAnimating];
        if (self.position == SVInfiniteScrollingPositionTop)
          [self resetScrollViewContentInset];
        break;
      }
      
      case SVInfiniteScrollingStateTriggered:
        [self.activityIndicatorView startAnimating];
        break;
        
      case SVInfiniteScrollingStateLoading:
        [self.activityIndicatorView startAnimating];
        [self setScrollViewContentInsetForInfiniteScrolling];
        break;
    }
  }
  
  if(previousState == SVInfiniteScrollingStateTriggered && newState == SVInfiniteScrollingStateLoading && self.infiniteScrollingHandler && self.enabled)
    self.infiniteScrollingHandler();
}

@end
