import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: page

    property alias cfg_popupCores: coresBox.checked
    property alias cfg_popupGpu: gpuBox.checked
    property alias cfg_popupMemory: memoryBox.checked
    property alias cfg_popupNetwork: networkBox.checked
    property alias cfg_popupDisk: diskBox.checked
    property alias cfg_popupBattery: batteryBox.checked
    property alias cfg_popupProcesses: processesBox.checked

    Kirigami.FormLayout {
        anchors.fill: parent

        QQC2.CheckBox {
            id: coresBox
            Kirigami.FormData.label: "Show in popup:"
            text: "Per-core load"
        }

        QQC2.CheckBox {
            id: gpuBox
            text: "Graphics cards"
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
            text: "Storage"
        }

        QQC2.CheckBox {
            id: batteryBox
            text: "Battery"
        }

        QQC2.CheckBox {
            id: processesBox
            text: "Top processes"
        }

        QQC2.Label {
            Kirigami.FormData.label: "Note:"
            text: "Sections that need extra sensors are only polled while the popup is open."
            wrapMode: Text.WordWrap
            opacity: 0.7
            font: Kirigami.Theme.smallFont
            Layout.fillWidth: true
            Layout.maximumWidth: Kirigami.Units.gridUnit * 18
        }
    }
}
