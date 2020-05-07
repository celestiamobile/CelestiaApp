//
//  LocalizationSwizzling.h
//  Celestia
//
//  Created by Levin Li on 2020/5/7.
//  Copyright © 2020 李林峰. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol IBLocalizable <NSObject, NSCoding>

- (void)localize;

@end

void SwizzleLocalizableClass(Class<IBLocalizable> cls);

NS_ASSUME_NONNULL_END
