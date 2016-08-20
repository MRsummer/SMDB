//
//  ViewController.m
//  SMDatabase
//
//  Created by ZhuGuangwen on 16/8/20.
//  Copyright © 2016年 ZhuGuangwen. All rights reserved.
//

#import "ViewController.h"
#import "SMDB.h"

@interface User : SMModel
@db_primary_property(strong, NSNumber *, uid, setUid);
@db_property(strong, NSString *, name, setName);
@db_property(assign, NSInteger, age, setAge);
@end

@implementation User
@end

@interface ViewController () <SMDatabaseMigrateProtocal>
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    SMDatabase *db = [SMDatabase databaseWithDBName:@"mydb" migrateDelegate:self];
    
    NSMutableArray *models = [NSMutableArray new];
    for (NSInteger i = 0;i < 100;i ++) {
        User *user = [User new];
        user.uid = @(i);
        user.name = [NSString stringWithFormat:@"user_%@", @(i)];
        user.age = i;
        
        [models addObject:user];
    }
    
    [db saveModelList:models withCallback:^(NSError *error) {
        if (error) {
            NSLog(@"save failed, %@", error);
        } else {
            NSLog(@"save success");
        }
    }];
    
    [db fetchModelClass:[User class] whereCondition:@"uid = 10" withCallback:^(NSArray<id<SMModelProtocal>> *arr, NSError *error) {
        if (error) {
            NSLog(@"fetch user error");
        } else if (arr.count == 0) {
            NSLog(@"do not find user");
        } else {
            User *user = arr.firstObject;
            NSLog(@"get user %@,%@,%@", user.uid, user.name, @(user.age));
        }
    }];
}

- (NSInteger)smdbCurrentDatabaseVersion {
    return 1;
}

- (NSString *)smdbMigrateSQLWithVersion:(NSInteger)version {
    if (version == 1) {
        return @"CREATE TABLE `USER` (uid INTEGER PRIMARY KEY, name TEXT, age INTEGER);";
    }
    return nil;
}

@end
