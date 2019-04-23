#import <Cephei/HBPreferences.h>
#import <MediaRemote/MediaRemote.h>
#import <Foundation/NSDistributedNotificationCenter.h>

#import "Tweak.h"
#import "../EXBTheme.h"

HBPreferences *preferences;
NSString *themeDirectory;
EXBTheme *theme;

bool enabled;
NSMutableArray *viewsToRelayout = [NSMutableArray new];
NSMutableArray *webViews = [NSMutableArray new];

@implementation EXBWebView

-(void)exoAction:(NSString *)action withArguments:(NSDictionary *)arguments {
    [super exoAction:action withArguments:arguments];
    if ([action isEqualToString:@"enableInteraction"]) {
        self.userInteractionEnabled = true;
    }
}

@end

%group Exobar

%hook UIStatusBar

%property (nonatomic, retain) EXBWebView *exbWebView;

-(void)layoutSubviews {
    %orig;
    if (!self.exbWebView) {
        self.exbWebView = [[EXBWebView alloc] initWithFrame:self.frame];
        [webViews addObject:self.exbWebView];
        self.exbWebView.opaque = false;
        [self addSubview:self.exbWebView];

        NSURL *nsUrl = [NSURL fileURLWithPath:[theme getPath:@"theme.html"]];
        NSURLRequest *request = [NSURLRequest requestWithURL:nsUrl];
        [self.exbWebView loadRequest:request];
    }

    for (UIView *view in [self subviews]) {
        if ([view isKindOfClass:%c(UIStatusBarForegroundView)]) {
            self.exbWebView.frame = view.frame;
            [view addSubview:self.exbWebView];
        }
    }

    [self.exbWebView exoInternalUpdate:@{
        @"exobar.cc": @(false),
        @"exobar.modern": @(false)
    }];

    bool dark = false;

    if (self.foregroundColor) {
        CGFloat white = 0;
        [self.foregroundColor getWhite:&white alpha:nil];
        dark = (white < 0.5);
    }

    [self.exbWebView exoInternalUpdate:@{
        @"exobar.dark": @(dark)
    }];
}

%end

%hook _UIStatusBar

%property (nonatomic, retain) EXBWebView *exbWebView;

-(id)initWithStyle:(long long)arg1 {
    %orig;
    [viewsToRelayout addObject:self.foregroundView];
    return self;
}

-(void)layoutSubviews {
    %orig;
    if (!self.exbWebView) {
        self.exbWebView = [[EXBWebView alloc] initWithFrame:self.foregroundView.frame];
        [webViews addObject:self.exbWebView];
        self.exbWebView.opaque = false;
        [self addSubview:self.exbWebView];

        NSURL *nsUrl = [NSURL fileURLWithPath:[theme getPath:@"theme.html"]];
        NSURLRequest *request = [NSURLRequest requestWithURL:nsUrl];
        [self.exbWebView loadRequest:request];
    }

    self.exbWebView.frame = self.foregroundView.frame;
    [self.foregroundView addSubview:self.exbWebView];

    bool dark = false;

    if (self.foregroundColor) {
        CGFloat white = 0;
        [self.foregroundColor getWhite:&white alpha:nil];
        dark = (white < 0.5);
    }

    [self.exbWebView exoInternalUpdate:@{
        @"exobar.dark": @(dark),
        @"exobar.modern": @(true)
    }];

    bool cc = ([self superview] && [[self superview] superview] && [self.superview.superview isKindOfClass:%c(CCUIStatusBar)]);
    [self.exbWebView exoInternalUpdate:@{
        @"exobar.cc": @(cc)
    }];
}

%end

%hook UIStatusBarForegroundView

-(id)initWithFrame:(CGRect)arg1 foregroundStyle:(id)arg2 usesVerticalLayout:(BOOL)arg3 {
    %orig;
    [viewsToRelayout addObject:self];
    return self;
}

-(void)layoutSubviews {
    %orig;
    for (UIView *view in [self subviews]) {
        if (![view isKindOfClass:%c(EXBWebView)]) {
            view.hidden = enabled;
        } else {
            view.hidden = !enabled;
        }
    }
}

%end

%hook _UIStatusBarForegroundView

-(void)layoutSubviews {
    %orig;
    for (UIView *view in [self subviews]) {
        if (![view isKindOfClass:%c(EXBWebView)]) {
            view.hidden = enabled;
        } else {
            view.hidden = !enabled;
        }
    }
}

%end

%end

void refreshAll() {
    for (EXBWebView *view in webViews) {
        [view reload];
    }
}

void relayoutAll() {
    for (UIView *view in viewsToRelayout) {
        [view layoutSubviews];
    }
}

%ctor {
    if (![NSProcessInfo processInfo]) return;
    NSString *processName = [NSProcessInfo processInfo].processName;
    bool isSpringboard = [@"SpringBoard" isEqualToString:processName];

    // Someone smarter than me invented this.
    // https://www.reddit.com/r/jailbreak/comments/4yz5v5/questionremote_messages_not_enabling/d6rlh88/
    bool shouldLoad = NO;
    NSArray *args = [[NSClassFromString(@"NSProcessInfo") processInfo] arguments];
    NSUInteger count = args.count;
    if (count != 0) {
        NSString *executablePath = args[0];
        if (executablePath) {
            NSString *processName = [executablePath lastPathComponent];
            BOOL isApplication = [executablePath rangeOfString:@"/Application/"].location != NSNotFound || [executablePath rangeOfString:@"/Applications/"].location != NSNotFound;
            BOOL isFileProvider = [[processName lowercaseString] rangeOfString:@"fileprovider"].location != NSNotFound;
            BOOL skip = [processName isEqualToString:@"AdSheet"]
                        || [processName isEqualToString:@"CoreAuthUI"]
                        || [processName isEqualToString:@"InCallService"]
                        || [processName isEqualToString:@"MessagesNotificationViewService"]
                        || [executablePath rangeOfString:@".appex/"].location != NSNotFound;
            if ((!isFileProvider && isApplication && !skip) || isSpringboard) {
                shouldLoad = YES;
            }
        }
    }

    if (!shouldLoad) return;

    preferences = [[HBPreferences alloc] initWithIdentifier:@"me.nepeta.exobar"];
    [preferences registerBool:&enabled default:YES forKey:@"Enabled"];
    [preferences registerObject:&themeDirectory default:@"default" forKey:@"Theme"];
    [preferences registerPreferenceChangeBlock:^() {
        theme = [EXBTheme themeWithDirectoryName:themeDirectory];
        relayoutAll();
        for (EXBWebView *view in webViews) {
            NSURL *nsUrl = [NSURL fileURLWithPath:[theme getPath:@"theme.html"]];
            NSURLRequest *request = [NSURLRequest requestWithURL:nsUrl];
            [view loadRequest:request];
        }
    }];

    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)refreshAll, (CFStringRef)EXBRefreshNotification, NULL, (CFNotificationSuspensionBehavior)kNilOptions);

    %init(Exobar);
}