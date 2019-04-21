#import <Cephei/HBPreferences.h>
#import <MediaRemote/MediaRemote.h>
#import <Foundation/NSDistributedNotificationCenter.h>

#import "Tweak.h"

HBPreferences *preferences;
NSString *themeUrl = @"/Library/Exobar/default/theme.html";

bool enabled;

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
        self.exbWebView.opaque = false;
        [self addSubview:self.exbWebView];

        NSURL *nsUrl = [NSURL fileURLWithPath:themeUrl];
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

-(void)layoutSubviews {
    %orig;
    if (!self.exbWebView) {
        self.exbWebView = [[EXBWebView alloc] initWithFrame:self.foregroundView.frame];
        self.exbWebView.opaque = false;
        [self addSubview:self.exbWebView];

        NSURL *nsUrl = [NSURL fileURLWithPath:themeUrl];
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

-(void)addSubview:(id)view {
    if ([view isKindOfClass:%c(EXBWebView)]) {
        %orig;
    }
}

-(void)insertSubview:(id)view atIndex:(int)x { }

%end

%hook _UIStatusBarForegroundView

-(void)layoutSubviews {
    %orig;
    for (UIView *view in [self subviews]) {
        if (![view isKindOfClass:%c(EXBWebView)]) {
            view.hidden = YES;
        }
    }
}

%end

%end


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
    [preferences registerDefaults:@{
        @"Enabled": @YES,
    }];

    [preferences registerBool:&enabled default:YES forKey:@"Enabled"];

    %init(Exobar);
}