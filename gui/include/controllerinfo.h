// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL

#ifndef CHIAKI_CONTROLLERINFO_H
#define CHIAKI_CONTROLLERINFO_H

#include <QHash>
#include <QObject>
#include <QProcess>
#include <QTimer>
#include <QVariantList>
#include <QVariantMap>

#ifdef CHIAKI_GUI_ENABLE_SDL_GAMECONTROLLER
#include <SDL.h>
#endif

// Read-only view of the connected game controllers for the Controllers settings page:
// description, battery, connection and (while `active`) the live input state.
class ControllerInfo : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList controllers READ controllers NOTIFY controllersChanged)
    Q_PROPERTY(int current READ current WRITE setCurrent NOTIFY currentChanged)
    Q_PROPERTY(bool active READ active WRITE setActive NOTIFY activeChanged)
    Q_PROPERTY(QVariantMap state READ state NOTIFY stateChanged)
    Q_PROPERTY(bool suspendUi READ suspendUi WRITE setSuspendUi NOTIFY suspendUiChanged)

public:
    explicit ControllerInfo(QObject *parent = nullptr);
    ~ControllerInfo() override;

    QVariantList controllers() const { return controller_list; }
    int current() const { return current_index; }
    void setCurrent(int index);
    bool active() const { return is_active; }
    void setActive(bool active);
    QVariantMap state() const { return input_state; }
    bool suspendUi() const { return suspend_ui; }
    void setSuspendUi(bool suspend);

public slots:
    void refresh();

signals:
    void controllersChanged();
    void currentChanged();
    void activeChanged();
    void stateChanged();
    void suspendUiChanged();
    void closeComboPressed(); // L1 + R1 + east face button, closes the test dialog

private:
    void poll();
    void closeAll();
    void queryBluetooth();
    void applyBluetooth();

#ifdef CHIAKI_GUI_ENABLE_SDL_GAMECONTROLLER
    QList<SDL_GameController *> opened;
#endif
    QVariantList controller_list;
    QVariantMap input_state;
    QHash<quint32, int> bluetooth_battery; // (vendor << 16 | product) -> percent, from system_profiler
    QProcess *bluetooth_process = nullptr;
    QTimer poll_timer;
    int current_index = 0;
    bool is_active = false;
    bool suspend_ui = false;
    bool combo_down = false;
};

#endif
