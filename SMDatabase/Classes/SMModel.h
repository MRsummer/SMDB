//
//  SMModel.h
//  wespy
//
//  Created by ZhuGuangwen on 16/8/18.
//  Copyright © 2016年 wepie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SMModelProtocal.h"

static NSString *const kDBPropertyPrefix = @"_smdb_";
static NSString *const kDBPrimaryPropertyPrefix = @"_smdb_primary_";

#define db_property(_arc_attr_, _type_, _getter_, _setter_) \
property (nonatomic, _arc_attr_, getter = _getter_, setter = _setter_:) _type_ _smdb_ ## _getter_

#define db_primary_property(_arc_attr_, _type_, _getter_, _setter_) \
property (nonatomic, _arc_attr_, getter = _getter_, setter = _setter_:) _type_ _smdb_primary_ ## _getter_

/**
 *
 *  note : <br> <br>
 *  use <br> `\@db_property(strong/weak/assign, type, name, setterName)` <br>
 *  to define a db property <br> <br>
 *  use <br> `\@db_primary_property(strong/weak/assign, type, name, setterName)` <br> 
 *  to define a db primary property <br> <br>
 *  do not use '_smdb_' in non-db-property's name  <br> <br>
 *  
 *  use `columNameForPropertyName:` to map the property name to the db colum name
 */
@interface SMModel : NSObject <SMModelProtocal>

#pragma mark - to be overide

+ (NSString *)columNameForPropertyName:(NSString *)propertyName;

@end
