//
//  CPUFrequencyMetric.h
//  CodeLab
//
//  Created by Jerome on 17/7/15.
//  Copyright © 2017年 goaftersoul. All rights reserved.
//

#ifndef CPUFrequencyMetric_B12861F8_693D_11E7_BF7C_28D2440E2EB2_H
#define CPUFrequencyMetric_B12861F8_693D_11E7_BF7C_28D2440E2EB2_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif // __cplusplus

/*  get current cpu frequency */    
int64_t CurrentCpuFrequency();

/* get hardware cpu frequency */
int64_t HardwareCpuFrequency();
    
#ifdef __cplusplus
}
#endif // __cplusplus

#endif /* CPUFrequencyMetric_B12861F8_693D_11E7_BF7C_28D2440E2EB2_H */
