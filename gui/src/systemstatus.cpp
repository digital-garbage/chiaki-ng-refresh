// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL

#include "systemstatus.h"

#ifdef Q_OS_MACOS
#include <IOKit/ps/IOPowerSources.h>
#include <IOKit/ps/IOPSKeys.h>
#include <CoreFoundation/CoreFoundation.h>
#endif

SystemStatus::SystemStatus(QObject *parent)
    : QObject(parent)
{
    timer.setInterval(30000);
    connect(&timer, &QTimer::timeout, this, &SystemStatus::refresh);
    timer.start();
    refresh();
}

void SystemStatus::refresh()
{
    bool battery = false;
    int percent = 0;
    bool charging = false;
#ifdef Q_OS_MACOS
    CFTypeRef info = IOPSCopyPowerSourcesInfo();
    if (info) {
        CFArrayRef sources = IOPSCopyPowerSourcesList(info);
        if (sources) {
            for (CFIndex i = 0; i < CFArrayGetCount(sources); i++) {
                CFDictionaryRef ps = IOPSGetPowerSourceDescription(info, CFArrayGetValueAtIndex(sources, i));
                if (!ps)
                    continue;
                auto type = static_cast<CFStringRef>(CFDictionaryGetValue(ps, CFSTR(kIOPSTypeKey)));
                if (!type || CFStringCompare(type, CFSTR(kIOPSInternalBatteryType), 0) != kCFCompareEqualTo)
                    continue;
                int current = 0, max = 0;
                auto cur_ref = static_cast<CFNumberRef>(CFDictionaryGetValue(ps, CFSTR(kIOPSCurrentCapacityKey)));
                auto max_ref = static_cast<CFNumberRef>(CFDictionaryGetValue(ps, CFSTR(kIOPSMaxCapacityKey)));
                if (cur_ref)
                    CFNumberGetValue(cur_ref, kCFNumberIntType, &current);
                if (max_ref)
                    CFNumberGetValue(max_ref, kCFNumberIntType, &max);
                if (max <= 0)
                    continue;
                battery = true;
                percent = current * 100 / max;
                auto state = static_cast<CFStringRef>(CFDictionaryGetValue(ps, CFSTR(kIOPSPowerSourceStateKey)));
                charging = state && CFStringCompare(state, CFSTR(kIOPSACPowerValue), 0) == kCFCompareEqualTo;
                break;
            }
            CFRelease(sources);
        }
        CFRelease(info);
    }
#endif
    if (battery == has_battery && percent == battery_percent && charging == is_charging)
        return;
    has_battery = battery;
    battery_percent = percent;
    is_charging = charging;
    emit changed();
}
