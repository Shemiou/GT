//
//  GTProcesserModel.m
//  GTKit
//
//  Created   on 12-10-18.
// Tencent is pleased to support the open source community by making
// Tencent GT (Version 2.4 and subsequent versions) available.
//
// Notwithstanding anything to the contrary herein, any previous version
// of Tencent GT shall not be subject to the license hereunder.
// All right, title, and interest, including all intellectual property rights,
// in and to the previous version of Tencent GT (including any and all copies thereof)
// shall be owned and retained by Tencent and subject to the license under the
// Tencent GT End User License Agreement (http://gt.qq.com/wp-content/EULA_EN.html).
//
// Copyright (C) 2015 THL A29 Limited, a Tencent company. All rights reserved.
//
// Licensed under the MIT License (the "License"); you may not use this file
// except in compliance with the License. You may obtain a copy of the License at
//
// http://opensource.org/licenses/MIT
//
// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
//


#ifndef GT_DEBUG_DISABLE

#import "GTThreadModel.h"
#import "GT.h"
#import "GTOutputList.h"
#import "GTLog.h"

#include <mach/mach.h>
#include <malloc/malloc.h>

#import <sys/sysctl.h>
#import <sys/types.h>
#import <sys/param.h>
#import <sys/mount.h>
#import <mach/processor_info.h>
#import <mach/mach_host.h>

#import <sys/utsname.h>
#include <stdint.h>
#include <inttypes.h>
#include "CPUFrequencyMetric.h"
#import "GTConfig.h"

@implementation GTThreadModel

static id object;

static int64_t currentCpuFrequency = 0LL;

M_GT_DEF_SINGLETION(GTThreadModel);

int64_t getCurrentCpuFrequency() {
    return currentCpuFrequency;
}

void updateCpuCurrentUsage(double cpuUsage) {
    //最高主频
    float maxFreq = [object getMaxFrequencyWithPhoneModel];
    //更新次数
    static uint32_t updateIndex = 0;
    static uint32_t zeroCpuUsageCount = 0;
    static double cpuUsageRecord[3] = {0.0};
    static int cpuUsageRecordCount = sizeof(cpuUsageRecord) / sizeof(cpuUsageRecord[0]);
    cpuUsageRecord[++updateIndex % cpuUsageRecordCount] = cpuUsage;
    zeroCpuUsageCount = cpuUsage <= 0.000001 && cpuUsage >= -0.000001 ? zeroCpuUsageCount + 1 : 0;
    do {
        if (zeroCpuUsageCount > 3) {
            break;
        }
        static uint32_t freqChangePercentMonitorCount = 3;
        static uint32_t highEnergyConsumptionMonitorCount = 0;
        static uint32_t normalEnergyConsumptionMonitorCount = 0;
        freqChangePercentMonitorCount -= freqChangePercentMonitorCount > 0 ? 1 : 0;
        //当前主频
        highEnergyConsumptionMonitorCount += currentCpuFrequency / maxFreq > 0.45 ? 1 : 0;
        ++normalEnergyConsumptionMonitorCount;
        if ((freqChangePercentMonitorCount <= 0)
            && (highEnergyConsumptionMonitorCount < 3)
            && (normalEnergyConsumptionMonitorCount < 10)) {
            double sumCpuUsage = 0.0;
            for (int i=0; i<cpuUsageRecordCount; ++i) {
                sumCpuUsage += cpuUsageRecord[i];
            }
            double avgCpuUsage = sumCpuUsage / cpuUsageRecordCount;
            cpuUsage = cpuUsage <= 0.000001 && cpuUsage >= -0.000001 ? 0.001 : cpuUsage;
            avgCpuUsage = avgCpuUsage <= 0.000001 && avgCpuUsage >= -0.000001 ? 0.001 : avgCpuUsage;
            double ratio = cpuUsage <= avgCpuUsage ? cpuUsage / avgCpuUsage : avgCpuUsage / cpuUsage;
            if (ratio > 0.80 && (cpuUsage - cpuUsageRecord[(updateIndex - 1) % cpuUsageRecordCount]) < 8.0 && (cpuUsage - cpuUsageRecord[(updateIndex - 1) % cpuUsageRecordCount]) > -8.0) {
                break;
            }
        }
        highEnergyConsumptionMonitorCount = 0;
        normalEnergyConsumptionMonitorCount = 0;
        int64_t cpuFrequencyValue = CurrentCpuFrequency() / 1000000;
        if (llabs(currentCpuFrequency - cpuFrequencyValue) / maxFreq > 0.17857) {
            freqChangePercentMonitorCount = 3;
        }
        currentCpuFrequency = cpuFrequencyValue;
        
    } while (false);
}

- (float)getMaxFrequencyWithPhoneModel{
    struct utsname systemInfo;
    
    uname(&systemInfo);
    
    NSString *platform = [NSString stringWithCString:systemInfo.machine encoding:NSASCIIStringEncoding];
    
    //iPhone 6 Plus
    if ([platform isEqualToString:@"iPhone7,1"]) return 1400.0;
    
    //iPhone 6
    if ([platform isEqualToString:@"iPhone7,2"]) return 1400.0;
    
    //iPhone 6s Plus
    if ([platform isEqualToString:@"iPhone8,2"]) return 1848.0;
    
    //iPhone 6s
    if ([platform isEqualToString:@"iPhone8,1"]) return 1848.0;
    
    //iPhone 7
    if ([platform isEqualToString:@"iPhone9,1"]) return 2339.0;
    
    //iPhone 7 Plus
    if ([platform isEqualToString:@"iPhone9,2"]) return 2339.0;
}

+ (void)saveDataToLocal:(NSString*)crashInfo
{
    // 获取到document下面的文件：
    NSString *sysDirPath = [NSString stringWithFormat:@"%@/%@", [[GTConfig sharedInstance] usrDir], M_GT_SYS_DIR];
    // 如果文件夹不存在，创建一个
    if (![[NSFileManager defaultManager] fileExistsAtPath:sysDirPath])
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:sysDirPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat : @"yyyy年M月d日 H点m分ss秒"];
    NSString* str = [formatter stringFromDate:[NSDate date]];
    [formatter release];
    
    NSString* filePath =[str stringByAppendingFormat:@"%@", @".log"];
    
    FILE *file = fopen([[sysDirPath stringByAppendingPathComponent:filePath] UTF8String], "a+");
    
    if (file) {
        fprintf(file, "%s", [crashInfo UTF8String]);
        fflush(file);
        fclose(file);
    }
    
    NSLog(@"%@", crashInfo);
}

-(id) init
{
    self = [super init];
    if (self) {
        GT_OUT_REGISTER("App CPU", "CPU");
        GT_OUT_HISTORY_CHECKED_SET("App CPU", true);
        GT_OC_OUT_DELEGATE_SET(@"App CPU", self);
    }
    
    return self;
}

-(void) dealloc
{
    [super dealloc];
}


- (void)handleTick
{
    [self getCpuUsage];
    GT_OUT_SET("App CPU", false, "%0.2f%%", cpu_usage);
}

- (float)getCpuUsage
{
    kern_return_t           kr;
    thread_array_t          thread_list;
    mach_msg_type_number_t  thread_count;
    thread_info_data_t      thinfo;
    mach_msg_type_number_t  thread_info_count;
    thread_basic_info_t     basic_info_th;
    
    kr = task_threads(mach_task_self(), &thread_list, &thread_count);
    if (kr != KERN_SUCCESS) {
        return -1;
    }
    cpu_usage = 0;
    
    for (int i = 0; i < thread_count; i++)
    {
        thread_info_count = THREAD_INFO_MAX;
        kr = thread_info(thread_list[i], THREAD_BASIC_INFO,(thread_info_t)thinfo, &thread_info_count);
        if (kr != KERN_SUCCESS) {
            return -1;
        }
        
        basic_info_th = (thread_basic_info_t)thinfo;

        if (!(basic_info_th->flags & TH_FLAGS_IDLE))
        {
            cpu_usage += basic_info_th->cpu_usage;
        }
    }
    
    cpu_usage = cpu_usage / (float)TH_USAGE_SCALE * 100.0;
    
    vm_deallocate(mach_task_self(), (vm_offset_t)thread_list, thread_count * sizeof(thread_t));
    
    updateCpuCurrentUsage(cpu_usage);
    
    float maxFreq = [self getMaxFrequencyWithPhoneModel];
    
    cpu_usage = getCurrentCpuFrequency() * cpu_usage / maxFreq;
    
    //    [[GTLog sharedInstance] addLog:[NSString stringWithFormat:@"CPU运算后占用：%f || 当前机型最高主频：%f",cpu_usage,maxFreq] tag:@"INFO" forLevel:GT_LOG_INFO];
    
    return cpu_usage;
}


#pragma mark - GTParaDelegate

- (void)switchEnable
{
    [[GTCoreModel sharedInstance] enableMonitor:[self class] withInterval:0];
}

- (void)switchDisable
{
    [[GTCoreModel sharedInstance] disableMonitor:[self class]];
}
- (NSString *)yDesc
{
    return @"%";
}

@end

double func_cpuUsage()
{
    return [[GTThreadModel sharedInstance] getCpuUsage];
}

#endif
