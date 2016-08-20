//
//  SMModel.m
//  wespy
//
//  Created by ZhuGuangwen on 16/8/18.
//  Copyright © 2016年 wepie. All rights reserved.
//

#import "SMModel.h"
#import "SMDB.h"
#import <objc/runtime.h>

static NSString *const kDBPropertyNamesKey = @"dbFieldNames";
static NSString *const kDBColumNameToPropertyNameDictKey = @"dbColumNameToPerpertyNameDict";
static NSString *const kDBPrimaryPropertyName = @"dbPrimaryKeyName";

static dispatch_queue_t _sm_exec_queue;
static NSMutableDictionary *_sm_global_modelInfoDict;

@implementation SMModel

#pragma mark - model info

+ (void)initialize {
    //TODO: 研究下initialize的调用时机
    [self setupModelInfo];
}

+ (void)setupModelInfo {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sm_exec_queue = dispatch_queue_create("com.wepie.wespy.SMModel", DISPATCH_QUEUE_SERIAL);
        _sm_global_modelInfoDict = [NSMutableDictionary new];
    });
    
    if ([NSStringFromClass(self) isEqualToString:@"SMModel"]) {
        //SMModel class does not need to set model info
        SMLog(@"load SMModel class, return");
        return;
    }
    SMLog(@"load %@ class, add", NSStringFromClass(self));
    
    dispatch_sync(_sm_exec_queue, ^{
        NSMutableArray *dbPropertyNames = [NSMutableArray new];
        NSString *dbPrimaryPropertyName = nil;
        unsigned int count = 0;
        objc_property_t *properties = class_copyPropertyList(self, &count);
        for (NSInteger i = 0;i < count;i ++) {
            NSString *key = [NSString stringWithUTF8String:property_getName(properties[i])];
            if ([key hasPrefix:kDBPrimaryPropertyPrefix]) {
                dbPrimaryPropertyName = [key stringByReplacingOccurrencesOfString:kDBPrimaryPropertyPrefix withString:@""];
                [dbPropertyNames addObject:dbPrimaryPropertyName];
            } else if ([key hasPrefix:kDBPropertyPrefix]) {
                [dbPropertyNames addObject:[key stringByReplacingOccurrencesOfString:kDBPropertyPrefix withString:@""]];
            }
        }
        free(properties);
        
        NSMutableDictionary *dbColumNameToPropertyNameDict = [NSMutableDictionary new];
        for (NSString *dbPropertyName in dbPropertyNames) {
            dbColumNameToPropertyNameDict[[self columNameForPropertyName:dbPropertyName]] = dbPropertyName;
        }
        
        NSString *className = NSStringFromClass(self);
        NSAssert(dbPropertyNames.count != 0, @"there's no db field in class %@", className);
        NSAssert(dbPrimaryPropertyName, @"primary key can not be nil in class %@", className);
        
        NSMutableDictionary *modelInfo = [NSMutableDictionary new];
        modelInfo[kDBPropertyNamesKey] = dbPropertyNames;
        modelInfo[kDBPrimaryPropertyName] = dbPrimaryPropertyName;
        modelInfo[kDBColumNameToPropertyNameDictKey] = dbColumNameToPropertyNameDict;
        _sm_global_modelInfoDict[NSStringFromClass(self)] = modelInfo;
    });
}

+ (NSDictionary *)getModelInfo {
    __block NSDictionary *modelInfo = nil;
    dispatch_sync(_sm_exec_queue, ^{
        modelInfo = _sm_global_modelInfoDict[NSStringFromClass(self.class)];
    });
    return modelInfo;
}

#pragma mark - SMModelProtocal implementation

- (NSString *)tableName {
    return NSStringFromClass(self.class);
}

- (NSString *)primaryKeyName {
    NSString *propertyName = [self.class getModelInfo][kDBPrimaryPropertyName];
    return [self.class columNameForPropertyName:propertyName];
}

- (id)primaryKeyValue {
    NSString *propertyName = [self.class getModelInfo][kDBPrimaryPropertyName];
    return [self valueForDBProperty:propertyName isPrimary:YES];
}

- (NSArray *)modelColumNames {
    NSMutableArray *propertyNames = [self.class getModelInfo][kDBPropertyNamesKey];
    NSMutableArray *columNames = [NSMutableArray new];
    for (NSString *propertyName in propertyNames) {
        [columNames addObject:[self.class columNameForPropertyName:propertyName]];
    }
    return columNames;
}

- (NSDictionary *)modelColumValueDict {
    NSString *primaryPropertyName = [self.class getModelInfo][kDBPrimaryPropertyName];
    NSMutableArray *propertyNames = [self.class getModelInfo][kDBPropertyNamesKey];
    
    NSMutableDictionary *valueDict = [NSMutableDictionary new];
    for (NSString *propertyName in propertyNames) {
        NSString *columName = [self.class columNameForPropertyName:propertyName];
        BOOL isPrimary = [propertyName isEqualToString:primaryPropertyName];
        valueDict[columName] = [self valueForDBProperty:propertyName isPrimary:isPrimary];
    }
    return valueDict;
}

+ (id<SMModelProtocal>)modelFromDict:(NSDictionary *)dict {
    NSDictionary *modelInfo = [self.class getModelInfo];
    NSMutableDictionary *columNameToPropertyNameDict = modelInfo[kDBColumNameToPropertyNameDictKey];
    NSString *primaryPropertyName = [self.class getModelInfo][kDBPrimaryPropertyName];
    
    id model = [self new];
    [dict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull columName, id  _Nonnull value, BOOL * _Nonnull stop) {
        NSString *propertyName = columNameToPropertyNameDict[columName];
        BOOL isPrimary = [propertyName isEqualToString:primaryPropertyName];
        if ([value isKindOfClass:[NSNull class]]) {
            [model setValue:nil forDBProperty:propertyName isPrimary:isPrimary];
        } else {
            [model setValue:value forDBProperty:propertyName isPrimary:isPrimary];
        }
    }];
    return model;
}

- (NSString *)origPropertyNameForPropertyName:(NSString *)propertyName isPrimary:(BOOL)isPrimary {
    NSString *prefix = isPrimary ? kDBPrimaryPropertyPrefix : kDBPropertyPrefix;
    return [NSString stringWithFormat:@"%@%@", prefix, propertyName];
}

- (_Nonnull id)valueForDBProperty:(NSString *)propertyName isPrimary:(BOOL)isPrimary {
    id value = [self valueForKey:[self origPropertyNameForPropertyName:propertyName isPrimary:isPrimary]];
    return value ? value : [NSNull null];
}

- (void)setValue:(id)value forDBProperty:(NSString *)propertyName isPrimary:(BOOL)isPrimary {
    [self setValue:value forKey:[self origPropertyNameForPropertyName:propertyName isPrimary:isPrimary]];
}

#pragma mark - to be overide

+ (NSString *)columNameForPropertyName:(NSString *)propertyName {
    return propertyName;
}

@end
