import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: page

    property alias cfg_popupArt: artBox.checked
    property alias cfg_popupSeek: seekBox.checked
    property alias cfg_popupVolume: volumeBox.checked
    property alias cfg_popupVisualizer: visualizerBox.checked
    property alias cfg_popupPlayers: playersBox.checked

    Kirigami.FormLayout {
        anchors.fill: parent

        QQC2.CheckBox {
            id: artBox
            Kirigami.FormData.label: "Show in popup:"
            text: "Album art"
        }

        QQC2.CheckBox {
            id: visualizerBox
            text: "Equalizer"
        }

        QQC2.CheckBox {
            id: seekBox
            text: "Position and seek bar"
        }

        QQC2.CheckBox {
            id: volumeBox
            text: "Volume"
        }

        QQC2.CheckBox {
            id: playersBox
            text: "Player list, when more than one is running"
        }
    }
}
