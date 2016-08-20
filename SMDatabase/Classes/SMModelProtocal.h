//
//  SMModelProtocal.h
//  wespy
//
//  Created by ZhuGuangwen on 16/8/18.
//  Copyright © 2016年 wepie. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SMModelProtocal <NSObject>

@required
- (NSString *)tableName;
- (NSString *)primaryKeyName;
- (id)primaryKeyValue;
- (NSArray *)modelColumNames;
- (NSDictionary *)modelColumValueDict;
+ (id<SMModelProtocal>)modelFromDict:(NSDictionary *)dict;

@optional
+ (NSString *)createTableSQL;

@end