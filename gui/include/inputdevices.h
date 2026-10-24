// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL

#ifndef CHIAKI_INPUTDEVICES_H
#define CHIAKI_INPUTDEVICES_H

#include <QDateTime>
#include <QHash>
#include <QObject>
#include <QProcess>
#include <QVariantList>

// Read-only view of the connected keyboards and mice for the Keyboard and mouse settings page:
// name, connection type and battery (wireless devices only). Backed by the macOS IORegistry.
class InputDevices : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList keyboards READ keyboards NOTIFY devicesChanged)
    Q_PROPERTY(QVariantList mice READ mice NOTIFY devicesChanged)

public:
    explicit InputDevices(QObject *parent = nullptr) : QObject(parent) {}

    QVariantList keyboards() const { return keyboard_list; }
    QVariantList mice() const { return mouse_list; }

public slots:
    void refresh();

signals:
    void devicesChanged();

private:
    void queryBluetooth();
    void applyBluetooth();

    QVariantList keyboard_list;
    QVariantList mouse_list;
    QHash<quint32, int> bluetooth_battery; // (vendor << 16 | product) -> percent, from system_profiler
    QProcess *bluetooth_process = nullptr;
    QDateTime bluetooth_queried;
};

#endif
