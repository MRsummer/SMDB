//
//  SMDatabase+Model.h
//  wespy
//
//  Created by ZhuGuangwen on 16/8/18.
//  Copyright © 2016年 wepie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SMDatabase.h"
#import "SMModelProtocal.h"

typedef void (^SMDatabaseFetchModelCallback) (NSArray<id<SMModelProtocal>> *arr, NSError *error);

//note : param whereCondition should exclude the 'WHERE' keyword
@interface SMDatabase (Model)

- (void)saveModel:(id<SMModelProtocal>)model withCallback:(SMDatabaseUpdateCallback)callback;
- (void)saveModelList:(NSArray<id<SMModelProtocal>> *)modelList withCallback:(SMDatabaseUpdateCallback)callback;

- (void)updateModelClass:(Class)aClass key:(NSString *)key value:(id)value
          whereCondition:(NSString *)whereCondition withCallback:(SMDatabaseUpdateCallback)callback;
- (void)updateModelClass:(Class)aClass keys:(NSArray *)keys values:(NSArray *)values
          whereCondition:(NSString *)whereCondition withCallback:(SMDatabaseUpdateCallback)callback;

- (void)deleteModel:(id<SMModelProtocal>)model withCallback:(SMDatabaseUpdateCallback)callback;
- (void)deleteModelClass:(Class)aClass whereCondition:(NSString *)whereCondition withCallback:(SMDatabaseUpdateCallback)callback;

- (void)fetchModelClass:(Class)aClass whereCondition:(NSString *)whereCondition withCallback:(SMDatabaseFetchModelCallback)callback;
- (void)fetchAllModelClass:(Class)aClass withCallback:(SMDatabaseFetchModelCallback)callback;

@end
