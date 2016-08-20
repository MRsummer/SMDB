//
//  SMDatabase.m
//  wespy
//
//  Created by ZhuGuangwen on 16/8/18.
//  Copyright © 2016年 wepie. All rights reserved.
//

#import "SMDatabase.h"
#import "FMDatabaseQueue.h"
#import "FMDatabase.h"
#import "SMDB.h"

@implementation SMDatabase {
    id<SMDatabaseMigrateProtocal> _migrateDelegate;
    FMDatabaseQueue *_databaseQueue;
    dispatch_queue_t _execQueue;
}

+ (instancetype)databaseWithDBName:(NSString *)dbName migrateDelegate:(id<SMDatabaseMigrateProtocal>)delegate {
    if (!dbName) {
        SMLog(@"warning : initWithDBName , but no dbName provided");
        return nil;
    }
    NSString *libDir = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject];
    NSString *dbPath = [libDir stringByAppendingPathComponent:dbName];
    return [self databaseWithDBPath:dbPath migrateDelegate:delegate];
}

+ (instancetype)databaseWithDBPath:(NSString *)dbPath migrateDelegate:(id<SMDatabaseMigrateProtocal>)delegate {
    return [[self alloc] initWithDBPath:dbPath migrateDelegate:delegate];
}

- (instancetype)initWithDBPath:(NSString *)dbPath migrateDelegate:(id<SMDatabaseMigrateProtocal>)delegate {
    if (!dbPath) {
        SMLog(@"warning : initWithDBPath , but no dbPath provided");
        return nil;
    }
    
    if (self = [super init]) {
        _migrateDelegate = delegate;
        _execQueue = dispatch_queue_create("com.wepie.wespy.smdatabase", DISPATCH_QUEUE_SERIAL);
        _databaseQueue = [self setupDatabaseWithDBPath:dbPath];
        
        if (!_databaseQueue) {
            SMLog(@"error : initWithDBPath, error creating or open database");
            return nil;
        }
        
        if (_migrateDelegate) {
            [self migrate];
        }
    }
    return self;
}

- (instancetype)init {
    NSAssert(0, @"call `[[SMDatabase alloc] initWithDBName]` instead");
    return nil;
}

- (FMDatabaseQueue *)setupDatabaseWithDBPath:(NSString *)dbPath {
    NSString *checkFilePath = [dbPath stringByDeletingLastPathComponent];
    NSFileManager *defaultFileManager = [NSFileManager defaultManager];
    if (![defaultFileManager fileExistsAtPath:checkFilePath]) {
        [defaultFileManager createDirectoryAtPath:checkFilePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return [FMDatabaseQueue databaseQueueWithPath:dbPath];
}

#pragma mark - handle migrate

- (void)migrate {
    NSInteger dbVersion = [self dbVersion];
    NSInteger currentVersion = [_migrateDelegate smdbCurrentDatabaseVersion];
    SMLog(@"dbVersion:%@ currentVersion:%@", @(dbVersion), @(currentVersion));
    
    if (dbVersion == currentVersion) {
        return;
    }
    
    NSMutableString *migrateSQL = [NSMutableString new];
    for (NSInteger i = dbVersion + 1;i <= currentVersion;i ++) {
        NSString *sql = [_migrateDelegate smdbMigrateSQLWithVersion:i];
        if (sql) {
            [migrateSQL appendString:sql];
            [migrateSQL appendString:@";"];
        }
    }
    __block BOOL migrateSuccess = YES;
    __block NSError *lastError;
    if (migrateSQL.length > 0) {
        [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            migrateSuccess = [db executeUpdate:migrateSQL];
            [db closeOpenResultSets];
            
            if (! migrateSuccess) {
                *rollback = YES;
                lastError = [db lastError];
            }
        }];
    }
    
    if (migrateSuccess) {
        [self setDBVersion:currentVersion];
    } else {
        if ([_migrateDelegate respondsToSelector:@selector(smdbMigrateError:)]) {
            [_migrateDelegate smdbMigrateError:lastError];
        }
    }
}

- (void)setDBVersion:(NSInteger)version {
    NSString *sql = [NSString stringWithFormat:@"PRAGMA user_version = %@;", @(version)];
    [_databaseQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:sql];
        [db closeOpenResultSets];
    }];
}

- (NSInteger)dbVersion {
    __block NSInteger version = kSMDatabaseInitVersion;
    [_databaseQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *result = [db executeQuery:@"PRAGMA user_version;"];
        if ([result next]) {
            version = [result intForColumnIndex:0];
        }
        [result close];
    }];
    return version;
}

- (void)inQueueWithBlock:(void(^)(void))block {
    dispatch_async(_execQueue, block);
}

#pragma mark - operation

- (void)updateWithSql:(NSString *)sql arguments:(NSArray *)arguments callback:(SMDatabaseUpdateCallback)callback {
    SMLog(@"exec sql-->%@", sql);
    dispatch_async(_execQueue, ^{
        [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            
            BOOL success = [db executeUpdate:sql withArgumentsInArray:arguments];
            if (!callback) {
                return;
            }
            
            NSError *error = success ? nil : [db lastError];
            dispatch_async(dispatch_get_main_queue(), ^{
                callback(error);
            });
            
        }];
    });
}

-(void)fetchWithSql:(NSString *)sql arguments:(NSArray *)arguments callback:(SMDatabaseFetchCallback)callback {
    SMLog(@"exec sql-->%@", sql);
    if (!callback) {
        return;
    }
    
    dispatch_async(_execQueue, ^{
        [_databaseQueue inDatabase:^(FMDatabase *db) {
            
            FMResultSet *resultSet = [db executeQuery:sql withArgumentsInArray:arguments];
            
            if (!resultSet) {
                callback(nil, [db lastError]);
                return;
            }
            
            NSMutableArray<NSDictionary *> *arr = [NSMutableArray<NSDictionary *> array];
            while (resultSet.next) {
                [arr addObject:[resultSet resultDictionary]];
            }
            [resultSet close];
            callback(arr, nil);
            
        }];
    });
}

@end
