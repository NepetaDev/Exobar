#include "EXBTheme.h"

@implementation EXBTheme

+ (EXBTheme *)themeWithDirectoryName:(NSString *)name {
    return [EXBTheme themeWithPath:[EXBThemesDirectory stringByAppendingPathComponent:name]];
}

+ (EXBTheme *)themeWithPath:(NSString*)path {
    return [[EXBTheme alloc] initWithPath:path];
}

- (NSString *)getPath:(NSString *)filename {
    return [self.path stringByAppendingPathComponent:filename];
}

- (id)initWithPath:(NSString*)path {
    BOOL isDir = NO;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir];
    
    if (!exists || !isDir) {
        return nil;
    }
    
    if ((self = [super init])) {
        self.path = path;
        self.name = [[path lastPathComponent] stringByDeletingPathExtension];
    }
    return self;
}

@end