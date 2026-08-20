import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: page

    property string cfg_visualizerStyle
    property alias cfg_visualizerBars: barsBox.value
    property alias cfg_visualizerSpeed: speedBox.value
    property string cfg_visualizerColor
    property alias cfg_visualizerWhenPaused: pausedBox.checked

    Kirigami.FormLayout {
        anchors.fill: parent

        QQC2.ComboBox {
            id: styleBox
            Kirigami.FormData.label: "Style:"
            textRole: "label"
            valueRole: "key"
            model: [
                { key: "bars", label: "Bars" },
                { key: "blocks", label: "Blocks" },
                { key: "wave", label: "Wave" },
                { key: "dots", label: "Dots" },
                { key: "pulse", label: "Pulse" }
            ]
            currentIndex: Math.max(0, indexOfValue(page.cfg_visualizerStyle))
            onActivated: page.cfg_visualizerStyle = currentValue
        }

        /* The preview runs whatever is selected, at the size the panel would
           give it. */
        Rectangle {
            Kirigami.FormData.label: "Preview:"
            Layout.preferredWidth: Kirigami.Units.gridUnit * 12
            Layout.preferredHeight: Kirigami.Units.gridUnit * 3
            radius: Kirigami.Units.cornerRadius
            color: Qt.rgba(Kirigami.Theme.textColor.r,
                           Kirigami.Theme.textColor.g,
                           Kirigami.Theme.textColor.b,
                           0.07)

            Visualizer {
                anchors.centerIn: parent
                width: parent.width - Kirigami.Units.largeSpacing * 2
                height: parent.height - Kirigami.Units.largeSpacing
                style: page.cfg_visualizerStyle
                bars: barsBox.value
                speed: speedBox.value
                color: Kirigami.Theme.highlightColor
                active: true
                seed: 4242
            }
        }

        QQC2.SpinBox {
            id: barsBox
            Kirigami.FormData.label: "Columns:"
            from: 3
            to: 24
            stepSize: 1
            enabled: page.cfg_visualizerStyle !== "pulse"
        }

        QQC2.SpinBox {
            id: speedBox
            Kirigami.FormData.label: "Speed:"
            from: 25
            to: 200
            stepSize: 5
            textFromValue: function (value) {
                return value + " %"
            }
            valueFromText: function (text) {
                return parseInt(text) || 100
            }
        }

        QQC2.ComboBox {
            id: colorBox
            Kirigami.FormData.label: "Colour:"
            textRole: "label"
            valueRole: "key"
            model: [
                { key: "album", label: "From the album art" },
                { key: "accent", label: "Accent colour" },
                { key: "theme", label: "Text colour" }
            ]
            currentIndex: Math.max(0, indexOfValue(page.cfg_visualizerColor))
            onActivated: page.cfg_visualizerColor = currentValue
        }

        QQC2.CheckBox {
            id: pausedBox
            Kirigami.FormData.label: "While paused:"
            text: "Keep moving"
        }

        QQC2.Label {
            Layout.maximumWidth: Kirigami.Units.gridUnit * 20
            text: "The equalizer is an indicator, not a spectrum analyser: a "
                  + "panel widget cannot read the audio stream, so the motion "
                  + "is generated from the track rather than measured from it."
            wrapMode: Text.WordWrap
            opacity: 0.6
            font: Kirigami.Theme.smallFont
        }
    }
}
