// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL

#include "controllerinfo.h"
#include "controllermanager.h"

#include <QtGlobal>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>

#ifdef CHIAKI_GUI_ENABLE_SDL_GAMECONTROLLER
namespace {
struct ButtonName
{
    SDL_GameControllerButton button;
    const char *name;
};

const ButtonName button_names[] = {
    {SDL_CONTROLLER_BUTTON_A, "a"},
    {SDL_CONTROLLER_BUTTON_B, "b"},
    {SDL_CONTROLLER_BUTTON_X, "x"},
    {SDL_CONTROLLER_BUTTON_Y, "y"},
    {SDL_CONTROLLER_BUTTON_BACK, "back"},
    {SDL_CONTROLLER_BUTTON_GUIDE, "guide"},
    {SDL_CONTROLLER_BUTTON_START, "start"},
    {SDL_CONTROLLER_BUTTON_LEFTSTICK, "ls"},
    {SDL_CONTROLLER_BUTTON_RIGHTSTICK, "rs"},
    {SDL_CONTROLLER_BUTTON_LEFTSHOULDER, "lb"},
    {SDL_CONTROLLER_BUTTON_RIGHTSHOULDER, "rb"},
    {SDL_CONTROLLER_BUTTON_DPAD_UP, "up"},
    {SDL_CONTROLLER_BUTTON_DPAD_DOWN, "down"},
    {SDL_CONTROLLER_BUTTON_DPAD_LEFT, "left"},
    {SDL_CONTROLLER_BUTTON_DPAD_RIGHT, "right"},
    {SDL_CONTROLLER_BUTTON_MISC1, "misc1"},
    {SDL_CONTROLLER_BUTTON_PADDLE1, "p1"},
    {SDL_CONTROLLER_BUTTON_PADDLE2, "p2"},
    {SDL_CONTROLLER_BUTTON_PADDLE3, "p3"},
    {SDL_CONTROLLER_BUTTON_PADDLE4, "p4"},
    {SDL_CONTROLLER_BUTTON_TOUCHPAD, "touchpad"},
};

double axisValue(SDL_GameController *gc, SDL_GameControllerAxis axis)
{
    return qBound(-1.0, SDL_GameControllerGetAxis(gc, axis) / 32767.0, 1.0);
}

bool isEliteProduct(Uint16 vendor, Uint16 product, const QString &name)
{
    if (name.contains(QStringLiteral("Elite"), Qt::CaseInsensitive))
        return true;
    // Xbox Elite Series 1 (0x02e3, 0x02ea) and Series 2 (USB 0x0b00, Bluetooth 0x0b05 / 0x0b22)
    return vendor == 0x045e && (product == 0x02e3 || product == 0x0b00 || product == 0x0b05 || product == 0x0b22);
}
} // namespace
#endif

ControllerInfo::ControllerInfo(QObject *parent)
    : QObject(parent)
{
    poll_timer.setInterval(16);
    connect(&poll_timer, &QTimer::timeout, this, &ControllerInfo::poll);
    connect(ControllerManager::GetInstance(), &ControllerManager::AvailableControllersUpdated, this, &ControllerInfo::refresh);
    refresh();
}

ControllerInfo::~ControllerInfo()
{
    closeAll();
}

void ControllerInfo::closeAll()
{
#ifdef CHIAKI_GUI_ENABLE_SDL_GAMECONTROLLER
    for (auto gc : std::as_const(opened))
        SDL_GameControllerClose(gc);
    opened.clear();
#endif
}

void ControllerInfo::setCurrent(int index)
{
    if (index == current_index)
        return;
    current_index = index;
    emit currentChanged();
    poll();
}

void ControllerInfo::setActive(bool active)
{
    if (active == is_active)
        return;
    is_active = active;
    if (active) {
        refresh();
        poll_timer.start();
    } else {
        poll_timer.stop();
    }
    emit activeChanged();
}

void ControllerInfo::refresh()
{
    closeAll();
    controller_list.clear();
#ifdef CHIAKI_GUI_ENABLE_SDL_GAMECONTROLLER
    for (int i = 0; i < SDL_NumJoysticks(); i++) {
        if (!SDL_IsGameController(i))
            continue;
        SDL_GameController *gc = SDL_GameControllerOpen(i);
        if (!gc)
            continue;
        opened.append(gc);

        SDL_Joystick *js = SDL_GameControllerGetJoystick(gc);
        const QString name = QString::fromUtf8(SDL_GameControllerName(gc));
        const Uint16 vendor = SDL_GameControllerGetVendor(gc);
        const Uint16 product = SDL_GameControllerGetProduct(gc);
        const bool elite = isEliteProduct(vendor, product, name);

        QString kind = QStringLiteral("generic");
        QString description = name;
        switch (SDL_GameControllerGetType(gc)) {
        case SDL_CONTROLLER_TYPE_XBOX360:
        case SDL_CONTROLLER_TYPE_XBOXONE:
            kind = elite ? QStringLiteral("elite") : QStringLiteral("xbox");
            if (elite)
                description = tr("Xbox Elite Wireless Controller");
            break;
        case SDL_CONTROLLER_TYPE_PS3:
        case SDL_CONTROLLER_TYPE_PS4:
        case SDL_CONTROLLER_TYPE_PS5:
            kind = QStringLiteral("playstation");
            break;
        case SDL_CONTROLLER_TYPE_NINTENDO_SWITCH_PRO:
            kind = QStringLiteral("switch");
            break;
        default:
            if (elite)
                kind = QStringLiteral("elite");
            break;
        }

        // SDL reports coarse battery levels only, and no connection type: "wired" power means USB,
        // any battery level means a wireless link (Bluetooth on macOS)
        int battery = -1;
        QString battery_text = tr("Unknown");
        QString connection = tr("Unknown");
        switch (SDL_JoystickCurrentPowerLevel(js)) {
        case SDL_JOYSTICK_POWER_EMPTY:
            battery = 0;
            battery_text = tr("Empty");
            connection = tr("Bluetooth");
            break;
        case SDL_JOYSTICK_POWER_LOW:
            battery = 1;
            battery_text = tr("Low");
            connection = tr("Bluetooth");
            break;
        case SDL_JOYSTICK_POWER_MEDIUM:
            battery = 2;
            battery_text = tr("Medium");
            connection = tr("Bluetooth");
            break;
        case SDL_JOYSTICK_POWER_FULL:
            battery = 4;
            battery_text = tr("Full");
            connection = tr("Bluetooth");
            break;
        case SDL_JOYSTICK_POWER_WIRED:
            battery = 4;
            battery_text = tr("Wired");
            connection = tr("USB");
            break;
        default:
            break;
        }

        if (vendor == 0x045e && connection == tr("Unknown")) {
            // known Xbox product ids: Bluetooth (Elite 2, Series X|S, One S) and USB (Elite 1/2, Series X|S, One)
            if (product == 0x0b22 || product == 0x0b05 || product == 0x0b13 || product == 0x02fd || product == 0x02e0)
                connection = tr("Bluetooth");
            else if (product == 0x0b00 || product == 0x0b12 || product == 0x02ea || product == 0x02d1 || product == 0x02dd || product == 0x02e3)
                connection = tr("USB");
        }

        bool has_paddles = false;
        for (auto b : {SDL_CONTROLLER_BUTTON_PADDLE1, SDL_CONTROLLER_BUTTON_PADDLE2, SDL_CONTROLLER_BUTTON_PADDLE3, SDL_CONTROLLER_BUTTON_PADDLE4})
            has_paddles = has_paddles || SDL_GameControllerHasButton(gc, b);

        QVariantMap entry;
        entry[QStringLiteral("name")] = name;
        entry[QStringLiteral("id")] = (quint32(vendor) << 16) | product;
        entry[QStringLiteral("description")] = description;
        entry[QStringLiteral("kind")] = kind;
        entry[QStringLiteral("elite")] = elite;
        entry[QStringLiteral("hasPaddles")] = has_paddles;
        entry[QStringLiteral("hasTouchpad")] = SDL_GameControllerHasButton(gc, SDL_CONTROLLER_BUTTON_TOUCHPAD) == SDL_TRUE;
        entry[QStringLiteral("battery")] = battery;
        entry[QStringLiteral("batteryText")] = battery_text;
        entry[QStringLiteral("connection")] = connection;
        controller_list.append(entry);
    }
#endif
    applyBluetooth();
    if (current_index >= controller_list.size()) {
        current_index = 0;
        emit currentChanged();
    }
    emit controllersChanged();
    poll();
    queryBluetooth();
}

// SDL cannot read the battery of a Bluetooth Xbox pad on macOS, system_profiler can
void ControllerInfo::queryBluetooth()
{
#ifdef Q_OS_MACOS
    if (bluetooth_process || controller_list.isEmpty())
        return;
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
        emit controllersChanged();
    });
    bluetooth_process->start(QStringLiteral("/usr/sbin/system_profiler"), {QStringLiteral("SPBluetoothDataType"), QStringLiteral("-json")});
#endif
}

void ControllerInfo::applyBluetooth()
{
    for (auto &value : controller_list) {
        QVariantMap entry = value.toMap();
        const auto it = bluetooth_battery.constFind(entry.value(QStringLiteral("id")).toUInt());
        if (it == bluetooth_battery.constEnd() || entry.value(QStringLiteral("battery")).toInt() >= 0)
            continue;
        entry[QStringLiteral("batteryPercent")] = it.value();
        entry[QStringLiteral("battery")] = qMin(4, (it.value() + 24) / 25);
        entry[QStringLiteral("batteryText")] = QStringLiteral("%1%").arg(it.value());
        entry[QStringLiteral("connection")] = tr("Bluetooth");
        value = entry;
    }
}

void ControllerInfo::poll()
{
    QVariantMap s;
#ifdef CHIAKI_GUI_ENABLE_SDL_GAMECONTROLLER
    if (current_index >= 0 && current_index < opened.size()) {
        SDL_GameController *gc = opened.at(current_index);
        s[QStringLiteral("lx")] = axisValue(gc, SDL_CONTROLLER_AXIS_LEFTX);
        s[QStringLiteral("ly")] = axisValue(gc, SDL_CONTROLLER_AXIS_LEFTY);
        s[QStringLiteral("rx")] = axisValue(gc, SDL_CONTROLLER_AXIS_RIGHTX);
        s[QStringLiteral("ry")] = axisValue(gc, SDL_CONTROLLER_AXIS_RIGHTY);
        s[QStringLiteral("lt")] = qMax(0.0, axisValue(gc, SDL_CONTROLLER_AXIS_TRIGGERLEFT));
        s[QStringLiteral("rt")] = qMax(0.0, axisValue(gc, SDL_CONTROLLER_AXIS_TRIGGERRIGHT));
        for (const auto &b : button_names)
            s[QString::fromLatin1(b.name)] = SDL_GameControllerGetButton(gc, b.button) != 0;
    }
#endif
    if (s != input_state) {
        input_state = s;
        emit stateChanged();
    }
}
