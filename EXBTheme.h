#define EXBPrefsIdentifier @"me.nepeta.exobar"
#define EXBNotification @"me.nepeta.exobar/ReloadPrefs"
#define EXBRefreshNotification @"me.nepeta.exobar/Refresh"
#define EXBThemesDirectory @"/Library/Exobar/"

@interface EXBTheme : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *path;
+ (EXBTheme *)themeWithDirectoryName:(NSString *)name;
+ (EXBTheme *)themeWithPath:(NSString *)path;
- (NSString *)getPath:(NSString *)filename;
- (id)initWithPath:(NSString *)path;

@end