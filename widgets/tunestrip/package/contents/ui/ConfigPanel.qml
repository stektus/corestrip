import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: page

    readonly property var orderedKeys: {
        var known = ["art", "visualizer", "text", "controls"]
        var wanted = String(cfg_panelOrder).split(",")
        var keys = []
        for (var i = 0; i < wanted.length; i++) {
            var key = wanted[i].trim()
            if (known.indexOf(key) >= 0 && keys.indexOf(key) < 0)
                keys.push(key)
        }
        for (var k = 0; k < known.length; k++) {
            if (keys.indexOf(known[k]) < 0)
                keys.push(known[k])
        }
        return keys
    }

    function keyLabel(key) {
        switch (key) {
        case "art": return "Album art"
        case "visualizer": return "Equalizer"
        case "text": return "Title"
        case "controls": return "Buttons"
        }
        return key
    }

    function keyEnabled(key) {
        switch (key) {
        case "art": return cfg_showArt
        case "visualizer": return cfg_showVisualizer
        case "text": return cfg_showText
        case "controls": return cfg_showControls
        }
        return true
    }

    function moveKey(index, delta) {
        var keys = orderedKeys.slice()
        var target = index + delta
        if (target < 0 || target >= keys.length)
            return
        var moved = keys[index]
        keys[index] = keys[target]
        keys[target] = moved
        cfg_panelOrder = keys.join(",")
    }

    property alias cfg_showArt: artBox.checked
    property alias cfg_showVisualizer: visualizerBox.checked
    property alias cfg_showText: textBox.checked
    property alias cfg_showControls: controlsBox.checked
    property string cfg_panelOrder
    property alias cfg_fontScale: scaleBox.value
    property alias cfg_textWidthUnits: widthBox.value
    property alias cfg_showArtistLine: artistBox.checked
    property alias cfg_scrollText: scrollBox.checked
    property alias cfg_progressLine: progressBox.checked
    property alias cfg_hideWhenIdle: hideBox.checked
    property alias cfg_wheelVolume: wheelBox.checked
    property alias cfg_middleClickPause: middleBox.checked

    Kirigami.FormLayout {
        anchors.fill: parent

        QQC2.CheckBox {
            id: artBox
            Kirigami.FormData.label: "Show in panel:"
            text: "Album art"
        }

        QQC2.CheckBox {
            id: visualizerBox
            text: "Equalizer"
        }

        QQC2.CheckBox {
            id: textBox
            text: "Title"
        }

        QQC2.CheckBox {
            id: controlsBox
            text: "Previous / play / next"
        }

        /* Order of the panel items; the up/down buttons rewrite cfg_panelOrder. */
        ColumnLayout {
            Kirigami.FormData.label: "Order:"
            spacing: Kirigami.Units.smallSpacing

            Repeater {
                model: page.orderedKeys

                RowLayout {
                    id: orderRow

                    required property int index
                    required property string modelData

                    spacing: Kirigami.Units.smallSpacing

                    QQC2.Label {
                        text: page.keyLabel(orderRow.modelData)
                        opacity: page.keyEnabled(orderRow.modelData) ? 1 : 0.5
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 6
                    }

                    QQC2.ToolButton {
                        icon.name: "go-up"
                        display: QQC2.AbstractButton.IconOnly
                        text: "Move up"
                        enabled: orderRow.index > 0
                        onClicked: page.moveKey(orderRow.index, -1)
                    }

                    QQC2.ToolButton {
                        icon.name: "go-down"
                        display: QQC2.AbstractButton.IconOnly
                        text: "Move down"
                        enabled: orderRow.index < page.orderedKeys.length - 1
                        onClicked: page.moveKey(orderRow.index, 1)
                    }
                }
            }

            QQC2.Label {
                text: "Top to bottom is left to right in a horizontal panel."
                opacity: 0.6
                font: Kirigami.Theme.smallFont
            }
        }

        Item {
            Kirigami.FormData.isSection: false
            implicitHeight: Kirigami.Units.smallSpacing
        }

        QQC2.SpinBox {
            id: scaleBox
            Kirigami.FormData.label: "Text size:"
            /* Past ~150 % the title outgrows any panel and every value looks
               the same, so the range stops where it still bites. */
            from: 50
            to: 150
            stepSize: 5
            textFromValue: function (value) {
                return value + " %"
            }
            valueFromText: function (text) {
                return parseInt(text) || 100
            }
        }

        QQC2.SpinBox {
            id: widthBox
            Kirigami.FormData.label: "Title width:"
            from: 4
            to: 40
            stepSize: 1
            textFromValue: function (value) {
                return value + " units"
            }
            valueFromText: function (text) {
                return parseInt(text) || 12
            }
        }

        QQC2.CheckBox {
            id: artistBox
            text: "Second line with the artist"
        }

        QQC2.CheckBox {
            id: scrollBox
            text: "Scroll titles that do not fit"
        }

        Item {
            Kirigami.FormData.isSection: false
            implicitHeight: Kirigami.Units.smallSpacing
        }

        QQC2.CheckBox {
            id: progressBox
            Kirigami.FormData.label: "Behaviour:"
            text: "Progress line under the widget"
        }

        QQC2.CheckBox {
            id: hideBox
            text: "Collapse when nothing is playing"
        }

        QQC2.CheckBox {
            id: wheelBox
            text: "Scroll wheel changes the volume"
        }

        QQC2.CheckBox {
            id: middleBox
            text: "Middle click plays or pauses"
        }
    }
}
