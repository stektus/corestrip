/* One card per GPU.  Sensor availability differs a lot between vendors, so a
 * row appears once its sensor has produced a real reading and then stays —
 * letting rows come and go would resize the card while it is being read. */
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.ksysguard.sensors as Sensors
import "../code/util.js" as Util

Card {
    id: gpuCard

    property string gpuId: ""
    property string fallbackName: "GPU"
    property int interval: 2000
    property bool active: false

    readonly property real usageRatio: Util.clamp01(usage.value / 100)

    property bool hasTemperature: false
    property bool hasPower: false
    property bool hasClock: false
    property bool hasVram: false

    title: Util.shortGpuName(nameSensor.status === Sensors.Sensor.Ready ? nameSensor.value : fallbackName)
    accentColor: Util.accent.gpu
    headline: Util.percent(usage.value)

    Sensors.Sensor {
        id: nameSensor
        sensorId: gpuCard.gpuId ? gpuCard.gpuId + "/name" : ""
    }
    Sensors.Sensor {
        id: usage
        sensorId: gpuCard.gpuId ? gpuCard.gpuId + "/usage" : ""
        updateRateLimit: gpuCard.interval
        enabled: gpuCard.active
    }
    Sensors.Sensor {
        id: temperature
        sensorId: gpuCard.gpuId ? gpuCard.gpuId + "/temperature" : ""
        updateRateLimit: gpuCard.interval
        enabled: gpuCard.active
        onValueChanged: if (value > 0) gpuCard.hasTemperature = true
    }
    Sensors.Sensor {
        id: power
        sensorId: gpuCard.gpuId ? gpuCard.gpuId + "/power" : ""
        updateRateLimit: gpuCard.interval
        enabled: gpuCard.active
        onValueChanged: if (value > 0) gpuCard.hasPower = true
    }
    Sensors.Sensor {
        id: coreFrequency
        sensorId: gpuCard.gpuId ? gpuCard.gpuId + "/coreFrequency" : ""
        updateRateLimit: gpuCard.interval
        enabled: gpuCard.active
        onValueChanged: if (value > 0) gpuCard.hasClock = true
    }
    Sensors.Sensor {
        id: usedVram
        sensorId: gpuCard.gpuId ? gpuCard.gpuId + "/usedVram" : ""
        updateRateLimit: gpuCard.interval
        enabled: gpuCard.active
    }
    Sensors.Sensor {
        id: totalVram
        sensorId: gpuCard.gpuId ? gpuCard.gpuId + "/totalVram" : ""
        enabled: gpuCard.active
        onValueChanged: if (value > 0) gpuCard.hasVram = true
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.largeSpacing

        Ring {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 3.2
            Layout.preferredHeight: Kirigami.Units.gridUnit * 3.2
            Layout.alignment: Qt.AlignVCenter
            value: gpuCard.usageRatio
            ringColor: Util.loadColor(Util.accent.gpu, gpuCard.usageRatio)

            Text {
                anchors.centerIn: parent
                text: Math.round(gpuCard.usageRatio * 100)
                color: Kirigami.Theme.textColor
                font.pointSize: Kirigami.Theme.defaultFont.pointSize
                font.weight: Font.DemiBold
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            StatLine {
                label: "Temperature"
                value: Util.celsius(temperature.value)
                valueSample: "100°"
                visible: gpuCard.hasTemperature
                valueColor: temperature.value > 80 ? Util.accent.thermal : Kirigami.Theme.textColor
            }
            StatLine {
                label: "Clock"
                value: Util.hertz(coreFrequency.value)
                valueSample: "9.99 GHz"
                visible: gpuCard.hasClock
            }
            StatLine {
                label: "Power"
                value: Util.watts(power.value)
                valueSample: "999.9 W"
                visible: gpuCard.hasPower
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.smallSpacing
                spacing: Kirigami.Units.smallSpacing
                visible: gpuCard.hasVram

                StatLine {
                    label: "Video memory"
                    value: Util.bytes(usedVram.value) + " / " + Util.bytes(totalVram.value)
                    valueSample: "999 GiB / 999 GiB"
                }

                MeterBar {
                    Layout.fillWidth: true
                    value: totalVram.value > 0 ? usedVram.value / totalVram.value : 0
                    barColor: Util.accent.gpu
                }
            }
        }
    }
}
