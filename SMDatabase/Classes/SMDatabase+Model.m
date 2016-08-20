//
//  SMDatabase+Model.m
//  wespy
//
//  Created by ZhuGuangwen on 16/8/18.
//  Copyright © 2016年 wepie. All rights reserved.
//

#import "SMDatabase+Model.h"

@implementation SMDatabase (Model)

- (void)saveModel:(id<SMModelProtocal>)model withCallback:(SMDatabaseUpdateCallback)callback {
    [self saveModelList:@[model] withCallback:callback];
}

- (void)saveModelList:(NSArray<id<SMModelProtocal>> *)modelList withCallback:(SMDatabaseUpdateCallback)callback {
    if (modelList.count == 0) {
        return;
    }
    id<SMModelProtocal> firstModel = modelList.firstObject;
    NSArray *columNames = [firstModel modelColumNames];
    
    NSString *placeholderItem = [NSString stringWithFormat:@"(%@)", [[self.class arrayWithCount:columNames.count item:@"?"] componentsJoinedByString:@","]];
    NSString *placeholderString = [[self.class arrayWithCount:modelList.count item:placeholderItem] componentsJoinedByString:@","];
    
    NSMutableArray *valueList = [NSMutableArray new];
    [modelList enumerateObjectsUsingBlock:^(id<SMModelProtocal>  _Nonnull model, NSUInteger idx, BOOL * _Nonnull stop) {
        NSDictionary *modelDict = [model modelColumValueDict];
        for (NSInteger i = 0;i < columNames.count;i ++) {
            [valueList addObject:modelDict[columNames[i]]];
        }
    }];
    
    NSString *sql = [NSString stringWithFormat:@"INSERT OR REPLACE INTO `%@` (%@) VALUES %@", [firstModel tableName]
                     , [columNames componentsJoinedByString:@","], placeholderString];
    [self updateWithSql:sql arguments:valueList callback:callback];
}

+ (NSArray *)arrayWithCount:(NSInteger)count item:(id)item {
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:count];
    for (NSInteger i = 0;i < count;i ++) {
        arr[i] = item;
    }
    return arr;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)updateModelClass:(Class)aClass key:(NSString *)key value:(id)value
          whereCondition:(NSString *)whereCondition withCallback:(SMDatabaseUpdateCallback)callback {
    [self updateModelClass:aClass keys:@[key] values:@[value] whereCondition:whereCondition withCallback:callback];
}

- (void)updateModelClass:(Class)aClass keys:(NSArray *)keys values:(NSArray *)values
          whereCondition:(NSString *)whereCondition withCallback:(SMDatabaseUpdateCallback)callback {
    if (keys.count == 0 || values.count == 0) {
        return;
    }
    NSInteger count = keys.count < values.count ? keys.count : values.count;
    
    NSMutableArray *placeholderList = [NSMutableArray new];
    NSMutableArray *valueList = [NSMutableArray new];
    for (NSInteger i = 0;i < count;i ++) {
        [placeholderList addObject:[NSString stringWithFormat:@"%@ = ? ", keys[i]]];
        [valueList addObject:values[i]];
    }
    
    NSString *sql = [NSString stringWithFormat:@"UPDATE `%@` SET %@ %@", [self tableNameFromModelClass:aClass]
                     , [placeholderList componentsJoinedByString:@","], [self whereString:whereCondition]];
    [self updateWithSql:sql arguments:valueList callback:callback];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)deleteModelClass:(Class)aClass whereCondition:(NSString *)whereCondition withCallback:(SMDatabaseUpdateCallback)callback {
    NSString *sql = [NSString stringWithFormat:@"DELETE FROM `%@` %@", [self tableNameFromModelClass:aClass]
                     , [self whereString:whereCondition]];
    [self updateWithSql:sql arguments:nil callback:callback];
}

- (void)deleteModel:(id<SMModelProtocal>)model withCallback:(SMDatabaseUpdateCallback)callback {
    NSString *sql = [NSString stringWithFormat:@"DELETE FROM `%@` WHERE %@ = ?", [model tableName], [model primaryKeyName]];
    [self updateWithSql:sql arguments:[model primaryKeyValue] callback:callback];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)fetchModelClass:(Class)aClass whereCondition:(NSString *)whereCondition withCallback:(SMDatabaseFetchModelCallback)callback {
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM `%@` %@", [self tableNameFromModelClass:aClass]
                     , [self whereString:whereCondition]];
    [self fetchWithSql:sql arguments:nil callback:^(NSArray *resultArr, NSError *error) {
        if (error) {
            callback(nil, error);
            return;
        }
        [self inQueueWithBlock:^{
            NSMutableArray *arr = [NSMutableArray new];
            for (NSDictionary *dict in resultArr) {
                [arr addObject:[aClass modelFromDict:dict]];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                callback(arr, nil);
            });
        }];
    }];
}

- (void)fetchAllModelClass:(Class)aClass withCallback:(SMDatabaseFetchModelCallback)callback {
    [self fetchModelClass:aClass whereCondition:nil withCallback:callback];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSString *)whereString:(NSString *)whereCondition {
    return whereCondition ? [NSString stringWithFormat:@" WHERE %@", whereCondition] : @"";
}

- (NSString *)tableNameFromModelClass:(Class)aClass {
    id model = [aClass new];
    NSAssert([model conformsToProtocol:@protocol(SMModelProtocal)], @"%@ does not confirms to SMModelProtocal", aClass);
    return [model tableName];
}

@end
