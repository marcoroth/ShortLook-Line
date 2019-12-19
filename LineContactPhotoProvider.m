#import <sqlite3.h>
#import "FolderFinder.h"
#import "LineContactPhotoProvider.h"

@implementation LineContactPhotoProvider

- (DDNotificationContactPhotoPromiseOffer *)contactPhotoPromiseOfferForNotification:(DDUserNotification *)notification {
    NSString *userId = [notification applicationUserInfo][@"m"];

    NSString *containerPath = [FolderFinder findSharedFolder:@"group.com.linecorp.line"];

    NSString *preferencesPath = [NSString stringWithFormat:@"%@/Library/Preferences/group.com.linecorp.line.plist", containerPath];
    NSDictionary *preferences = [[NSDictionary alloc] initWithContentsOfFile:preferencesPath];
    NSString* accountId = [NSString stringWithFormat:@"P_%@", preferences[@"mid"]];

    NSString *databasePath = [NSString stringWithFormat:@"%@/Library/Application Support/PrivateStore/%@/Messages/Line.sqlite", containerPath, accountId];
    NSString *imageURL;

    const char *dbpath = [databasePath UTF8String];
    sqlite3 *_linedb;

    if (sqlite3_open(dbpath, &_linedb) == SQLITE_OK) {
      const char *stmt = [[NSString stringWithFormat:@"SELECT ZPICTUREURL FROM ZUSER WHERE ZMID = '%@';", userId] UTF8String];
      sqlite3_stmt *statement;

      if (sqlite3_prepare_v2(_linedb, stmt, -1, &statement, NULL) == SQLITE_OK) {
        if (sqlite3_step(statement) == SQLITE_ROW) {
          const unsigned char *result = sqlite3_column_text(statement, 0);
          if (result) {
            imageURL = [NSString stringWithUTF8String:(char *)result];
          }
        }
        sqlite3_finalize(statement);
      }
      sqlite3_close(_linedb);
    }

    if (imageURL) {
      imageURL = [NSString stringWithFormat:@"%@/Library/Caches/PrivateStore/%@/Profile Images%@/200x200.jpg", containerPath, accountId, imageURL];
      UIImage *image = [UIImage imageWithContentsOfFile:imageURL];

      return [NSClassFromString(@"DDNotificationContactPhotoPromiseOffer") offerInstantlyResolvingPromiseWithPhotoIdentifier:imageURL image:image];
    } else {
      return nil;
    }
  }
@end
