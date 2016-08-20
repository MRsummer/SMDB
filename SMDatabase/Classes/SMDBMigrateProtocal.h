//
//  SMDBMigrateDelegate.h
//  CTPersistenceTest
//
//  Created by ZhuGuangwen on 16/8/19.
//  Copyright © 2016年 ZhuGuangwen. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SMDatabaseMigrateProtocal <NSObject>

@required

/**
 * return the current the databaseVersion
 * the initial database version is kSMDatabaseInitVersion = -1
 * smdb will automatically figure out the update SQLs need to executed with migrateSQLWithVersion:
 */
- (NSInteger)smdbCurrentDatabaseVersion;

/**
 * return the SQL need to be executed on the specific version
 */
- (NSString *)smdbMigrateSQLWithVersion:(NSInteger)version;

@optional

/**
 * an error occured while migrating , you can delete the database and create a new one or do something else
 */
- (void)smdbMigrateError:(NSError *)error;

@end
