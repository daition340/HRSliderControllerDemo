//
//  HRSliderController.m
//  HRSliderControllerDemo
//
//  Created by Rannie on 13-10-7.
//  Copyright (c) 2013年 Rannie. All rights reserved.
//

#import "HRSliderController.h"
#import <QuartzCore/QuartzCore.h>

#import "LeftSliderController.h"
#import "RightSliderController.h"
#import "ClassModel.h"
#import "HRViewController.h"

#define RCloseDuration 0.3f
#define ROpenDuration 0.4f
#define RContentScale 0.83f
#define RContentOffset 220.0f
#define RJudgeOffset 100.0f

typedef NS_ENUM(NSInteger, RMoveDirection) {
    RMoveDirectionLeft = 0,
    RMoveDirectionRight
};

@interface HRSliderController ()
{
    UIView *_mainContentView;
    UIView *_leftSideView;
    UIView *_rightSideView;
    
    NSMutableDictionary *_controllersDict;

    UITapGestureRecognizer *_tapGestureRec;
    UIPanGestureRecognizer *_panGestureRec;
}

@end

static HRSliderController *sharedSC;
@implementation HRSliderController

+ (id)sharedSliderController
{
    return sharedSC;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedSC = self;
    });

    _controllersDict = [NSMutableDictionary dictionary];
    
    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"top_navigation_background.png"] forBarMetrics:UIBarMetricsDefault];
    
    [self initSubviews];
    
    [self initChildControllers];
    
    [self showContentControllerWithModel:[ClassModel classModelWithTitle:@"新闻" className:@"NewsViewController" contentText:@"新闻视图内容" andImageName:@"sidebar_nav_news"]];
    
    _tapGestureRec = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeSideBar)];
    [self.view addGestureRecognizer:_tapGestureRec];
    _tapGestureRec.enabled = NO;
    
    _panGestureRec = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveViewWithGesture:)];
    [_mainContentView addGestureRecognizer:_panGestureRec];
}

#pragma mark -
#pragma mark Intialize Method

- (void)initSubviews
{
    UIView *rv = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:rv];
    _rightSideView = rv;
    
    UIView *lv = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:lv];
    _leftSideView = lv;
    
    UIView *mv = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:mv];
    _mainContentView = mv;
}

- (void)initChildControllers
{
    LeftSliderController *leftSC = [[LeftSliderController alloc] init];
    [self addChildViewController:leftSC];
    [_leftSideView addSubview:leftSC.view];
    
    RightSliderController *rightSC = [[RightSliderController alloc] init];
    [self addChildViewController:rightSC];
    [_rightSideView addSubview:rightSC.view];
}

#pragma mark -
#pragma mark Actions

- (void)showContentControllerWithModel:(ClassModel *)model
{
    [self closeSideBar];
    
    UIViewController *controller = _controllersDict[model.className];
    if (!controller)
    {
        Class c = NSClassFromString(model.className);
        HRViewController *vc = [[c alloc] init];
        controller = [[UINavigationController alloc] initWithRootViewController:vc];
        
        vc.contentText = model.contentText;
        
        UILabel *titleLabel = [[UILabel alloc] init];
        titleLabel.frame = CGRectMake(0, 0, 100, 44);
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.font = [UIFont systemFontOfSize:22.0f];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.text = model.title;
        
        UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 44)];
        [titleView addSubview:titleLabel];
        
        UIButton *leftBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        leftBtn.bounds = CGRectMake(0, 0, 44, 44);
        [leftBtn setBackgroundImage:[UIImage imageNamed:@"top_navigation_menuicon.png"] forState:UIControlStateNormal];
        [leftBtn setBackgroundImage:[UIImage imageNamed:@"top_navigation_menuicon_highlighted.png"] forState:UIControlStateHighlighted];
        [leftBtn addTarget:self action:@selector(leftItemClick) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *leftItem = [[UIBarButtonItem alloc] initWithCustomView:leftBtn];
        
        UIButton *rightBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        rightBtn.bounds = CGRectMake(0, 0, 44, 44);
        [rightBtn setBackgroundImage:[UIImage imageNamed:@"top_navigation_infoicon"] forState:UIControlStateNormal];
        [rightBtn setBackgroundImage:[UIImage imageNamed:@"top_navigation_infoicon_highlighted"] forState:UIControlStateHighlighted];
        [rightBtn addTarget:self action:@selector(rightItemClick) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithCustomView:rightBtn];
        
        vc.navigationItem.rightBarButtonItem = rightItem;
        vc.navigationItem.leftBarButtonItem = leftItem;
        vc.navigationItem.titleView = titleView;
        
        [_controllersDict setObject:controller forKey:model.className];
    }
    
    if (_mainContentView.subviews.count > 0)
    {
        UIView *view = [_mainContentView.subviews firstObject];
        [view removeFromSuperview];
    }
    
    controller.view.frame = _mainContentView.frame;
    [_mainContentView addSubview:controller.view];
}
#define DEG2RAD(degrees) (degrees * M_PI / 180)
- (void)leftItemClick
{
    [self.view sendSubviewToBack:_rightSideView];
    [self configureViewShadowWithDirection:RMoveDirectionRight];
    
    CATransform3D contentTransform = CATransform3DIdentity;
    contentTransform.m34 = -1.0f / 800.0f;
    _mainContentView.layer.zPosition = 100;
    
    
    contentTransform = CATransform3DTranslate(contentTransform, 220 - (_mainContentView.frame.size.width / 2 * 0.4), 0.0, 0.0);
    //contentTransform = CATransform3DScale(contentTransform, 0.6, 0.6, 0.6);
    
    contentTransform = CATransform3DRotate(contentTransform, DEG2RAD(-45), 0.0, 1.0, 0.0);
    
    
    [UIView animateWithDuration:.3
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         _mainContentView.layer.transform = contentTransform;
                     }
                     completion:^(BOOL finished) {
                         
                     }];
    
    
    
    
    return;
    CGAffineTransform conT = [self transformWithDirection:RMoveDirectionRight];
    
    [self.view sendSubviewToBack:_rightSideView];
    [self configureViewShadowWithDirection:RMoveDirectionRight];
    
    [UIView animateWithDuration:ROpenDuration
                     animations:^{
                         _mainContentView.transform = conT;
                     }
                     completion:^(BOOL finished) {
                         _tapGestureRec.enabled = YES;
                     }];
}

- (void)rightItemClick
{
    CGAffineTransform conT = [self transformWithDirection:RMoveDirectionLeft];
    
    [self.view sendSubviewToBack:_leftSideView];
    [self configureViewShadowWithDirection:RMoveDirectionLeft];
    
    [UIView animateWithDuration:ROpenDuration
                     animations:^{
                         _mainContentView.transform = conT;
                     }
                     completion:^(BOOL finished) {
                         _tapGestureRec.enabled = YES;
                     }];
}

- (void)closeSideBar
{
    CGAffineTransform oriT = CGAffineTransformIdentity;
    [UIView animateWithDuration:RCloseDuration
                     animations:^{
                         _mainContentView.transform = oriT;
                     }
                     completion:^(BOOL finished) {
                         _tapGestureRec.enabled = NO;
                     }];
}

- (void)moveViewWithGesture:(UIPanGestureRecognizer *)panGes
{
    static CGFloat currentTranslateX;
    if (panGes.state == UIGestureRecognizerStateBegan)
    {
        currentTranslateX = _mainContentView.transform.tx;
    }
    if (panGes.state == UIGestureRecognizerStateChanged)
    {
        CGFloat transX = [panGes translationInView:_mainContentView].x;
        transX = transX + currentTranslateX;
        
        CGFloat sca;
        if (transX > 0)
        {
            [self.view sendSubviewToBack:_rightSideView];
            [self configureViewShadowWithDirection:RMoveDirectionRight];
            
            if (_mainContentView.frame.origin.x < RContentOffset)
            {
                sca = 1 - (_mainContentView.frame.origin.x/RContentOffset) * (1-RContentScale);
            }
            else
            {
                sca = RContentScale;
            }
        }
        else    //transX < 0
        {
            [self.view sendSubviewToBack:_leftSideView];
            [self configureViewShadowWithDirection:RMoveDirectionLeft];
            
            if (_mainContentView.frame.origin.x > -RContentOffset)
            {
                sca = 1 - (-_mainContentView.frame.origin.x/RContentOffset) * (1-RContentScale);
            }
            else
            {
                sca = RContentScale;
            }
        }
        CGAffineTransform transS = CGAffineTransformMakeScale(1.0, sca);
        CGAffineTransform transT = CGAffineTransformMakeTranslation(transX, 0);
        
        CGAffineTransform conT = CGAffineTransformConcat(transT, transS);
        
        _mainContentView.transform = conT;
    }
    else if (panGes.state == UIGestureRecognizerStateEnded)
    {
        CGFloat panX = [panGes translationInView:_mainContentView].x;
        CGFloat finalX = currentTranslateX + panX;
        if (finalX > RJudgeOffset)
        {
            CGAffineTransform conT = [self transformWithDirection:RMoveDirectionRight];
            [UIView beginAnimations:nil context:nil];
            _mainContentView.transform = conT;
            [UIView commitAnimations];
            
            _tapGestureRec.enabled = YES;
            return;
        }
        if (finalX < -RJudgeOffset)
        {
            CGAffineTransform conT = [self transformWithDirection:RMoveDirectionLeft];
            [UIView beginAnimations:nil context:nil];
            _mainContentView.transform = conT;
            [UIView commitAnimations];
            
            _tapGestureRec.enabled = YES;
            return;
        }
        else
        {
            CGAffineTransform oriT = CGAffineTransformIdentity;
            [UIView beginAnimations:nil context:nil];
            _mainContentView.transform = oriT;
            [UIView commitAnimations];
            
            _tapGestureRec.enabled = NO;
        }
    }
}

#pragma mark -
#pragma mark Private

- (CGAffineTransform)transformWithDirection:(RMoveDirection)direction
{
    CGFloat translateX = 0;
    switch (direction) {
        case RMoveDirectionLeft:
            translateX = -RContentOffset;
            break;
        case RMoveDirectionRight:
            translateX = RContentOffset;
            break;
        default:
            break;
    }
    
    MyLog(@"%.2f",translateX);
    CGAffineTransform transT = CGAffineTransformMakeTranslation(translateX, 0);
    CGAffineTransform scaleT = CGAffineTransformMakeScale(1.0, RContentScale);
    CGAffineTransform conT = CGAffineTransformConcat(transT, scaleT);
    
    return conT;
}

- (void)configureViewShadowWithDirection:(RMoveDirection)direction
{
    CGFloat shadowW;
    switch (direction)
    {
        case RMoveDirectionLeft:
            shadowW = 2.0f;
            break;
        case RMoveDirectionRight:
            shadowW = -2.0f;
            break;
        default:
            break;
    }
    
    _mainContentView.layer.shadowOffset = CGSizeMake(shadowW, 1.0);
    _mainContentView.layer.shadowColor = [UIColor blackColor].CGColor;
    _mainContentView.layer.shadowOpacity = 0.8f;
}

@end
