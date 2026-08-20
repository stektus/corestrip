/* Seven-day outlook: one row per day, with a bar spanning that day's range
   against the week's range — the shape tells you more than the numbers do. */
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "../code/util.js" as Util

ColumnLayout {
    id: list

    property var backend
    property var days: backend ? backend.forecast : []

    readonly property real weekLow: {
        var low = Number.POSITIVE_INFINITY
        for (var i = 0; i < days.length; i++)
            low = Math.min(low, days[i].low)
        return low === Number.POSITIVE_INFINITY ? 0 : low
    }
    readonly property real weekHigh: {
        var high = Number.NEGATIVE_INFINITY
        for (var i = 0; i < days.length; i++)
            high = Math.max(high, days[i].high)
        return high === Number.NEGATIVE_INFINITY ? 1 : high
    }
    readonly property real weekSpan: Math.max(1, weekHigh - weekLow)

    spacing: Math.round(Kirigami.Units.smallSpacing * 1.5)

    Repeater {
        model: list.days

        RowLayout {
            id: row

            required property var modelData
            required property int index

            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Text {
                text: row.index === 0 ? "Today" : Util.weekday(row.modelData.date, true)
                color: Kirigami.Theme.textColor
                opacity: row.index === 0 ? 0.9 : 0.6
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                font.weight: row.index === 0 ? Font.DemiBold : Font.Normal
                Layout.preferredWidth: Kirigami.Units.gridUnit * 2.4
            }

            WeatherGlyph {
                code: row.modelData.code
                day: true
                implicitWidth: Kirigami.Units.iconSizes.smallMedium
                implicitHeight: Kirigami.Units.iconSizes.smallMedium
            }

            Text {
                text: row.modelData.precipitation > 20 ? Util.percent(row.modelData.precipitation) : ""
                color: Util.accent.time
                opacity: 0.75
                font.pointSize: Math.max(6, Kirigami.Theme.smallFont.pointSize - 1)
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: Kirigami.Units.gridUnit * 1.6
            }

            Text {
                text: Util.temperature(row.modelData.low, "")
                color: Kirigami.Theme.textColor
                opacity: 0.5
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: Kirigami.Units.gridUnit * 1.4
            }

            /* Range bar: cold end blue, warm end orange. */
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.round(Kirigami.Units.gridUnit * 0.32)

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: Util.alpha(Kirigami.Theme.textColor, 0.12)
                }

                Rectangle {
                    x: parent.width * (row.modelData.low - list.weekLow) / list.weekSpan
                    width: Math.max(height,
                                    parent.width * (row.modelData.high - row.modelData.low) / list.weekSpan)
                    height: parent.height
                    radius: height / 2
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "#5ac8fa" }
                        GradientStop { position: 1.0; color: Util.accent.weather }
                    }
                }
            }

            Text {
                text: Util.temperature(row.modelData.high, "")
                color: Kirigami.Theme.textColor
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: Kirigami.Units.gridUnit * 1.6
            }
        }
    }
}
