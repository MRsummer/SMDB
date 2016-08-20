//
//  SMDatabase.h
//  wespy
//
//  Created by ZhuGuangwen on 16/8/18.
//  Copyright © 2016年 wepie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SMDBMigrateProtocal.h"

static const NSInteger kSMDatabaseInitVersion = -1;

typedef void(^SMDatabaseUpdateCallback) (NSError *error);
typedef void(^SMDatabaseFetchCallback) (NSArray<NSDictionary *> *resultArr, NSError *error);
/**
 *
 * SMDB is a wrapper of FMDB, it provides features as follows: <br><br>
 * - automatically create database <br> (see `databaseWithDBName:migrateDelegate:`) <br><br>
 * - manage the migration and provides migrate delegate for you <br> (see `databaseWithDBName:migrateDelegate:`) <br><br>
 * - provides only async api to ensure performance and avoid errors  <br><br>
 * - provides `SMModel` and `SMModelProtocal` which let you write your database model easily <br><br>
 * - provides save/delete/fetch ORM functions which let you directly interact with database using your `SMModel` subclass
 */
@interface SMDatabase : NSObject

+ (instancetype)databaseWithDBName:(NSString *)dbName migrateDelegate:(id<SMDatabaseMigrateProtocal>)delegate;
+ (instancetype)databaseWithDBPath:(NSString *)dbPath migrateDelegate:(id<SMDatabaseMigrateProtocal>)delegate;
- (instancetype)initWithDBPath:(NSString *)dbPath migrateDelegate:(id<SMDatabaseMigrateProtocal>)delegate;

- (void)updateWithSql:(NSString *)sql arguments:(NSArray *)arguments callback:(SMDatabaseUpdateCallback)callback;
- (void)fetchWithSql:(NSString *)sql arguments:(NSArray *)arguments callback:(SMDatabaseFetchCallback)callback;

//protected api
- (void)inQueueWithBlock:(void(^)(void))block;

@end