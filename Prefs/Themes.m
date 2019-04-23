#import "Themes.h"
#import "Preferences.h"

@interface EXBAlignedTableViewCell : UITableViewCell {
}
@end

#define MARGIN 5

@implementation EXBAlignedTableViewCell
- (void) layoutSubviews {
    [super layoutSubviews];
    CGRect cvf = self.contentView.frame;
      CGFloat width = 80;
    self.imageView.frame = CGRectMake(MARGIN,
                                      0.0,
                                      width,
                                      cvf.size.height-1);
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;

    CGRect frame = CGRectMake(width + MARGIN*2,
                              self.textLabel.frame.origin.y,
                              cvf.size.width - width - 3*MARGIN,
                              self.textLabel.frame.size.height);
    self.textLabel.frame = frame;

    frame = CGRectMake(width + MARGIN*2,
                       self.detailTextLabel.frame.origin.y,
                       cvf.size.width - width - 3*MARGIN,
                       self.detailTextLabel.frame.size.height);   
    self.detailTextLabel.frame = frame;
}
@end

@implementation EXBThemesListController

@synthesize themes = _themes;

- (id)initForContentSize:(CGSize)size {
    self = [super init];

    if (self) {
        self.themes = [[NSMutableArray alloc] initWithCapacity:100];
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height) style:UITableViewStyleGrouped];
        [_tableView setDataSource:self];
        [_tableView setDelegate:self];
        [_tableView setEditing:NO];
        [_tableView setAllowsSelection:YES];
        [_tableView setAllowsMultipleSelection:NO];
        
        if ([self respondsToSelector:@selector(setView:)])
            [self performSelectorOnMainThread:@selector(setView:) withObject:_tableView waitUntilDone:YES];        
    }

    return self;
}

- (void)addThemesFromDirectory:(NSString *)directory {
    NSFileManager *manager = [NSFileManager defaultManager];
    NSArray *diskThemes = [manager contentsOfDirectoryAtPath:directory error:nil];
    
    for (NSString *dirName in diskThemes) {
        NSString *path = [EXBThemesDirectory stringByAppendingPathComponent:dirName];
        EXBTheme *theme = [EXBTheme themeWithPath:path];
        
        if (theme) {
            //[theme preparePreviewImage];
            [self.themes addObject:theme];
        }
    }
}

- (void)refreshList {
    self.themes = [[NSMutableArray alloc] initWithCapacity:100];
    [self addThemesFromDirectory: EXBThemesDirectory];
            
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)];
    [self.themes sortUsingDescriptors:[NSArray arrayWithObject:descriptor]];
    [descriptor release];
    
    HBPreferences *file = [[HBPreferences alloc] initWithIdentifier:EXBPrefsIdentifier];
    selectedTheme = [([file objectForKey:@"Theme"] ?: @"Default") stringValue];
}

- (id)view {
    return _tableView;
}

- (void)viewWillAppear:(BOOL)animated {
    [self refreshList];
}

- (NSArray *)currentThemes {
    return self.themes;
}

- (void)dealloc { 
    self.themes = nil;
    [super dealloc];
}

- (NSString*)navigationTitle {
    return @"Themes";
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.currentThemes.count;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ThemeCell"];
    if (!cell) {
        cell = [[EXBAlignedTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ThemeCell"];
    }
    
    EXBTheme *theme = [self.currentThemes objectAtIndex:indexPath.row];
    cell.textLabel.text = theme.name;    
    //cell.imageView.image = theme.image;
    //cell.imageView.highlightedImage = theme.image;
    cell.selected = NO;

    if ([theme.name isEqualToString: selectedTheme] && !tableView.isEditing) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else if (!tableView.isEditing) {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    UITableViewCell *old = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow: [[self.currentThemes valueForKey:@"name"] indexOfObject: selectedTheme] inSection: 0]];
    if (old) old.accessoryType = UITableViewCellAccessoryNone;

    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;

    EXBTheme *theme = (EXBTheme*)[self.currentThemes objectAtIndex:indexPath.row];
    selectedTheme = theme.name;

    HBPreferences *file = [[HBPreferences alloc] initWithIdentifier:EXBPrefsIdentifier];
    [file setObject:selectedTheme forKey:@"Theme"];

    EXBPrefsListController *parent = (EXBPrefsListController *)self.parentController;
    [parent setThemeName:selectedTheme];

    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (CFStringRef)EXBNotification, nil, nil, true);
}

@end
