#import <Exo/EXOWebView.h>

@interface EXBWebView : EXOWebView

@end

@interface UIStatusBarForegroundStyleAttributes

@property (nonatomic, retain) UIColor *tintColor;

@end

@interface UIStatusBar : UIView

@property (nonatomic, retain) EXBWebView *exbWebView;
@property (nonatomic, retain) UIColor *foregroundColor;

@end

@interface _UIStatusBar : UIView

@property (nonatomic, retain) EXBWebView *exbWebView;
@property (nonatomic, retain) UIView *foregroundView;
@property (nonatomic, retain) UIColor *foregroundColor;

@end

@interface UIStatusBarForegroundView : UIView

@end

@interface _UIStatusBarForegroundView : UIView

@end