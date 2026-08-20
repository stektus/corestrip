import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: page

    property string cfg_compactStyle
    property alias cfg_showCpu: cpuBox.checked
    property alias cfg_showGpu: gpuBox.checked
    property alias cfg_showMemory: memoryBox.checked
    property alias cfg_showNetwork: networkBox.checked
    property alias cfg_showDisk: diskBox.checked
    property alias cfg_showTemperature: temperatureBox.checked
    property alias cfg_showLabels: labelsBox.checked
    property string cfg_panelGpu
    property alias cfg_updateInterval: intervalBox.realValue

    SensorInventory {
        id: inventory
    }

    Kirigami.FormLayout {
        anchors.fill: parent

        QQC2.ComboBox {
            id: styleBox
            Kirigami.FormData.label: "Gauge style:"
            textRole: "label"
            valueRole: "key"
            model: [
                { key: "combo", label: "Plot and readout" },
                { key: "rings", label: "Rings" },
                { key: "bars", label: "History bars" },
                { key: "text", label: "Numbers only" }
            ]
            currentIndex: Math.max(0, indexOfValue(page.cfg_compactStyle))
            onActivated: page.cfg_compactStyle = currentValue
        }

        QQC2.CheckBox {
            id: cpuBox
            Kirigami.FormData.label: "Show in panel:"
            text: "Processor"
        }

        QQC2.CheckBox {
            id: gpuBox
            text: "Graphics"
        }

        QQC2.CheckBox {
            id: memoryBox
            text: "Memory"
        }

        QQC2.CheckBox {
            id: networkBox
            text: "Network"
        }

        QQC2.CheckBox {
            id: diskBox
            text: "Disk activity"
        }

        Item {
            Kirigami.FormData.isSection: false
            implicitHeight: Kirigami.Units.smallSpacing
        }

        QQC2.CheckBox {
            id: temperatureBox
            text: "Show temperatures"
        }

        QQC2.CheckBox {
            id: labelsBox
            text: "Label each gauge"
            enabled: styleBox.currentValue !== "combo"
        }

        QQC2.ComboBox {
            id: gpuChoice
            Kirigami.FormData.label: "Graphics device:"
            enabled: inventory.gpus.length > 1
            textRole: "label"
            valueRole: "key"
            model: {
                var entries = [{ key: "auto", label: "Automatic" }]
                for (var i = 0; i < inventory.gpus.length; i++) {
                    entries.push({
                        key: inventory.gpus[i].id,
                        label: inventory.gpus[i].label
                    })
                }
                return entries
            }
            currentIndex: Math.max(0, indexOfValue(page.cfg_panelGpu))
            onActivated: page.cfg_panelGpu = currentValue
        }

        QQC2.SpinBox {
            id: intervalBox
            Kirigami.FormData.label: "Update every:"

            /* KConfig stores milliseconds; the spin box edits seconds. */
            property int realValue: 2000

            from: 1
            to: 30
            stepSize: 1
            value: Math.round(realValue / 1000)
            onValueModified: realValue = value * 1000
            textFromValue: function (value) {
                return value === 1 ? "1 second" : value + " seconds"
            }
            valueFromText: function (text) {
                return parseInt(text) || 2
            }
        }
    }
}
