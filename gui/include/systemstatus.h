// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL

#ifndef CHIAKI_SYSTEMSTATUS_H
#define CHIAKI_SYSTEMSTATUS_H

#include <QObject>
#include <QTimer>

// Battery of the machine that receives the stream (shown in the stream menu).
class SystemStatus : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool hasBattery READ hasBattery NOTIFY changed)
    Q_PROPERTY(int batteryPercent READ batteryPercent NOTIFY changed)
    Q_PROPERTY(bool charging READ charging NOTIFY changed)

public:
    explicit SystemStatus(QObject *parent = nullptr);

    bool hasBattery() const { return has_battery; }
    int batteryPercent() const { return battery_percent; }
    bool charging() const { return is_charging; }

public slots:
    void refresh();

signals:
    void changed();

private:
    QTimer timer;
    bool has_battery = false;
    int battery_percent = 0;
    bool is_charging = false;
};

#endif
