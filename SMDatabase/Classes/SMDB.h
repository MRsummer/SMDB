//
//  SMDB.h
//  CTPersistenceTest
//
//  Created by ZhuGuangwen on 16/8/19.
//  Copyright © 2016年 ZhuGuangwen. All rights reserved.
//

#ifndef SMDB_h
#define SMDB_h

#ifdef DEBUG
#define SMLog(_format_, ...) NSLog(_format_, ##__VA_ARGS__)
#else
#define SMLog(_format_, ...)
#endif

#import "SMDBMigrateProtocal.h"
#import "SMModelProtocal.h"
#import "SMDatabase.h"
#import "SMDatabase+Model.h"
#import "SMModel.h"

#endif /* SMDB_h */
