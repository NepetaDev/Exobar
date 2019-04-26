#import <Exo/EXOWebView.h>

@interface EXBWebView : EXOWebView

@end

@interface UIStatusBarForegroundStyleAttributes

@property (nonatomic, retain) UIColor *tintColor;

@end

@interface UIStatusBarStyleAttributes : NSObject

-(UIStatusBarForegroundStyleAttributes *)foregroundStyle;

@end

@interface UIStatusBar : UIView

@property (nonatomic, retain) EXBWebView *exbWebView;
@property (nonatomic, retain) UIColor *foregroundColor;

-(id)_currentStyleAttributes;

@end

@interface _UIStatusBarStyleAttributes : NSObject

-(UIColor *)textColor;

@end

@interface _UIStatusBar : UIView

@property (nonatomic,retain) _UIStatusBarStyleAttributes * styleAttributes;
@property (nonatomic, retain) EXBWebView *exbWebView;
@property (nonatomic, retain) UIView *foregroundView;
@property (nonatomic, retain) UIColor *foregroundColor;

@end

@interface UIStatusBarForegroundView : UIView

@end

@interface _UIStatusBarForegroundView : UIView

@end