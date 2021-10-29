//
// CelestiaLegacyMigrator.m
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

#import "CelestiaLegacyMigrator.h"
#include <pwd.h>

@implementation CelestiaLegacyMigrator

+ (NSInteger)supportedDataBaseVersion {
    return 1;
}

+ (NSInteger)dataBaseVersion {
    return [[NSUserDefaults standardUserDefaults] integerForKey:@"dbVersion"];
}

+ (void)tryToMigrate {
    if ([self dataBaseVersion] < [self supportedDataBaseVersion]) {
        [self migrateDataBaseFrom0To1];
    }
}

+ (void)migrateDataBaseFrom0To1 {
    if ([self dataBaseVersion] != 0)
        return;

    // get the real home path
    const char *home = getpwuid(getuid())->pw_dir;
    NSString *path = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:home length:strlen(home)];
    // get the preference file path of Celestia 1.6.1
    NSString *prefPath = [path stringByAppendingString:@"/Library/Preferences/net.shatters.Celestia.plist"];
    BOOL isDirectory;
    NSUserDefaults *currentSetting = [NSUserDefaults standardUserDefaults];
    if ([[NSFileManager defaultManager] fileExistsAtPath:prefPath isDirectory:&isDirectory] && !isDirectory) {
        // preference exists, try to read and apply
        NSDictionary<NSString *, id> *pref = [[NSDictionary alloc] initWithContentsOfFile:prefPath];
        if (pref) {
            // apply all preferences one by one
            [pref enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                [currentSetting setObject:obj forKey:key];
            }];
        }
    }
    // update db version
    [currentSetting setInteger:1 forKey:@"dbVersion"];
    [currentSetting synchronize];
}

@end
