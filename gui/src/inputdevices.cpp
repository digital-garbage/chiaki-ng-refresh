// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL

#include "inputdevices.h"

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>

#ifdef Q_OS_MACOS
#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/IOKitLib.h>
#endif

#ifdef Q_OS_MACOS
static QVariant registryValue(io_registry_entry_t entry, const char *key)
{
    CFStringRef cf_key = CFStringCreateWithCString(kCFAllocatorDefault, key, kCFStringEncodingUTF8);
    CFTypeRef value = IORegistryEntryCreateCFProperty(entry, cf_key, kCFAllocatorDefault, 0);
    CFRelease(cf_key);
    QVariant result;
    if (value) {
        if (CFGetTypeID(value) == CFStringGetTypeID())
            result = QString::fromCFString(static_cast<CFStringRef>(value));
        else if (CFGetTypeID(value) == CFNumberGetTypeID()) {
            int number = 0;
            CFNumberGetValue(static_cast<CFNumberRef>(value), kCFNumberIntType, &number);
            result = number;
        }
        CFRelease(value);
    }
    return result;
}
#endif

void InputDevices::refresh()
{
    QVariantList keyboards, mice;
#ifdef Q_OS_MACOS
    io_iterator_t iterator = 0;
    if (IOServiceGetMatchingServices(0, IOServiceMatching("IOHIDDevice"), &iterator) == KERN_SUCCESS) {
        QSet<QString> seen;
        while (io_registry_entry_t entry = IOIteratorNext(iterator)) {
            const int page = registryValue(entry, "PrimaryUsagePage").toInt();
            const int usage = registryValue(entry, "PrimaryUsage").toInt();
            const bool keyboard = page == 1 && usage == 6;
            const bool mouse = page == 1 && usage == 2;
            // virtual devices (Touch Bar, remote desktop tools) are not something the user plugged in
            if ((keyboard || mouse) && registryValue(entry, "Transport").toString() != QLatin1String("Virtual")) {
                QString name = registryValue(entry, "Product").toString();
                const QString transport = registryValue(entry, "Transport").toString();
                const quint32 vendor = registryValue(entry, "VendorID").toUInt();
                const quint32 product = registryValue(entry, "ProductID").toUInt();
                const QVariant percent = registryValue(entry, "BatteryPercent");
                const bool built_in = transport == QLatin1String("SPI") || transport == QLatin1String("FIFO")
                    || transport == QLatin1String("I2C") || transport == QLatin1String("AID") || name.contains(QLatin1String("Internal"));
                if (built_in)
                    name = keyboard ? tr("Built-in Keyboard") : tr("Built-in Trackpad");
                if (name.isEmpty())
                    name = keyboard ? tr("Keyboard") : tr("Mouse");

                QString connection = transport;
                if (built_in)
                    connection = tr("Built-in");
                else if (transport.startsWith(QLatin1String("Bluetooth")))
                    connection = tr("Bluetooth");
                else if (transport.isEmpty())
                    connection = tr("Unknown");

                // 0..4 segments like the controller card, -1 unknown
                int battery = -1;
                QString battery_text = tr("Unknown");
                if (built_in) {
                    battery_text = tr("Built-in");
                } else if (connection == QLatin1String("USB")) {
                    battery = 4;
                    battery_text = tr("Wired");
                } else if (percent.isValid()) {
                    battery = qMin(4, (percent.toInt() + 24) / 25);
                    battery_text = QStringLiteral("%1%").arg(percent.toInt());
                }

                const QString id = QStringLiteral("%1:%2:%3:%4").arg(keyboard).arg(vendor).arg(product).arg(name);
                if (!seen.contains(id)) {
                    seen.insert(id);
                    QVariantMap device;
                    device[QStringLiteral("name")] = name;
                    device[QStringLiteral("id")] = (vendor << 16) | product;
                    device[QStringLiteral("builtIn")] = built_in;
                    device[QStringLiteral("connection")] = connection;
                    device[QStringLiteral("battery")] = battery;
                    device[QStringLiteral("batteryText")] = battery_text;
                    (keyboard ? keyboards : mice).append(device);
                }
            }
            IOObjectRelease(entry);
        }
        IOObjectRelease(iterator);
    }
#endif
    keyboard_list = keyboards;
    mouse_list = mice;
    applyBluetooth();
    emit devicesChanged();
    queryBluetooth();
}

// Non-Apple Bluetooth devices report their battery only to system_profiler
void InputDevices::queryBluetooth()
{
#ifdef Q_OS_MACOS
    if (bluetooth_process || (bluetooth_queried.isValid() && bluetooth_queried.secsTo(QDateTime::currentDateTime()) < 30))
        return;
    bool needed = false;
    for (const auto &list : {keyboard_list, mouse_list})
        for (const auto &value : list)
            needed = needed || (value.toMap().value(QStringLiteral("connection")) == tr("Bluetooth") && value.toMap().value(QStringLiteral("battery")).toInt() < 0);
    if (!needed)
        return;
    bluetooth_queried = QDateTime::currentDateTime();
    bluetooth_process = new QProcess(this);
    connect(bluetooth_process, &QProcess::finished, this, [this]() {
        const auto doc = QJsonDocument::fromJson(bluetooth_process->readAllStandardOutput());
        bluetooth_process->deleteLater();
        bluetooth_process = nullptr;
        bluetooth_battery.clear();
        const auto sections = doc.object().value(QStringLiteral("SPBluetoothDataType")).toArray();
        for (const auto &section : sections) {
            const auto connected = section.toObject().value(QStringLiteral("device_connected")).toArray();
            for (const auto &entry : connected) {
                const auto devices = entry.toObject();
                for (auto it = devices.begin(); it != devices.end(); ++it) {
                    const auto device = it.value().toObject();
                    bool ok_vendor = false, ok_product = false;
                    const quint32 vendor = device.value(QStringLiteral("device_vendorID")).toString().toUInt(&ok_vendor, 16);
                    const quint32 product = device.value(QStringLiteral("device_productID")).toString().toUInt(&ok_product, 16);
                    const QString level = device.value(QStringLiteral("device_batteryLevelMain")).toString();
                    if (ok_vendor && ok_product && !level.isEmpty())
                        bluetooth_battery.insert((vendor << 16) | product, level.chopped(1).toInt());
                }
            }
        }
        applyBluetooth();
        emit devicesChanged();
    });
    bluetooth_process->start(QStringLiteral("/usr/sbin/system_profiler"), {QStringLiteral("SPBluetoothDataType"), QStringLiteral("-json")});
#endif
}

void InputDevices::applyBluetooth()
{
    for (auto *list : {&keyboard_list, &mouse_list}) {
        for (auto &value : *list) {
            QVariantMap device = value.toMap();
            const auto it = bluetooth_battery.constFind(device.value(QStringLiteral("id")).toUInt());
            if (it == bluetooth_battery.constEnd() || device.value(QStringLiteral("battery")).toInt() >= 0)
                continue;
            device[QStringLiteral("battery")] = qMin(4, (it.value() + 24) / 25);
            device[QStringLiteral("batteryText")] = QStringLiteral("%1%").arg(it.value());
            value = device;
        }
    }
}
