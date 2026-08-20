import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: page

    readonly property var orderedKeys: {
        var known = ["weather", "time", "date"]
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
        case "weather": return "Weather"
        case "time": return "Time"
        case "date": return "Date"
        }
        return key
    }

    function keyEnabled(key) {
        switch (key) {
        case "weather": return cfg_showWeather
        case "time": return cfg_showTime
        case "date": return cfg_showDate || cfg_showWeekday
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

    property alias cfg_showTime: timeBox.checked
    property alias cfg_showDate: dateBox.checked
    property alias cfg_showWeekday: weekdayBox.checked
    property alias cfg_showWeather: weatherBox.checked
    property alias cfg_use24Hour: hourBox.checked
    property alias cfg_showSeconds: secondsBox.checked
    property string cfg_dateFormat
    property alias cfg_firstDayMonday: mondayBox.checked
    property alias cfg_fontScale: scaleBox.value
    property string cfg_panelOrder

    property alias cfg_popupWeather: popupWeatherBox.checked
    property alias cfg_popupForecast: popupForecastBox.checked
    property alias cfg_popupCalendar: popupCalendarBox.checked
    property alias cfg_popupAgenda: popupAgendaBox.checked

    Kirigami.FormLayout {
        anchors.fill: parent

        QQC2.CheckBox {
            id: timeBox
            Kirigami.FormData.label: "Show in panel:"
            text: "Time"
        }

        QQC2.CheckBox {
            id: dateBox
            text: "Date"
        }

        QQC2.CheckBox {
            id: weekdayBox
            text: "Weekday"
        }

        QQC2.CheckBox {
            id: weatherBox
            text: "Weather"
        }

        QQC2.SpinBox {
            id: scaleBox
            Kirigami.FormData.label: "Text size:"
            /* Above ~150 % the clock would outgrow any panel and every value
               would look the same, so the range stops where it still bites. */
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
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 5
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

        QQC2.CheckBox {
            id: hourBox
            Kirigami.FormData.label: "Clock:"
            text: "24-hour format"
        }

        QQC2.CheckBox {
            id: secondsBox
            text: "Show seconds"
        }

        QQC2.ComboBox {
            id: formatBox
            Kirigami.FormData.label: "Date format:"
            textRole: "label"
            valueRole: "key"
            model: [
                { key: "compact", label: "30 Sep" },
                { key: "full", label: "Wednesday, 30 September" },
                { key: "iso", label: "2026-09-30" }
            ]
            currentIndex: Math.max(0, indexOfValue(page.cfg_dateFormat))
            onActivated: page.cfg_dateFormat = currentValue
        }

        QQC2.CheckBox {
            id: mondayBox
            Kirigami.FormData.label: "Calendar:"
            text: "Weeks start on Monday"
        }

        Item {
            Kirigami.FormData.isSection: false
            implicitHeight: Kirigami.Units.smallSpacing
        }

        QQC2.CheckBox {
            id: popupWeatherBox
            Kirigami.FormData.label: "Show in popup:"
            text: "Current weather"
        }

        QQC2.CheckBox {
            id: popupForecastBox
            text: "Seven-day forecast"
        }

        QQC2.CheckBox {
            id: popupCalendarBox
            text: "Month view"
        }

        QQC2.CheckBox {
            id: popupAgendaBox
            text: "Agenda"
        }
    }
}
