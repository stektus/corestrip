/* What lives in the panel: clock, date and current weather, each optional and
   arranged in whatever order the settings ask for.

   The repeater model is the ordered list of enabled keys — it changes only
   when the configuration does, so a ticking clock updates bindings instead of
   rebuilding items. */
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import "../code/util.js" as Util

MouseArea {
    id: compact

    property var backend
    signal toggleRequested()

    property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    property bool showTime: Plasmoid.configuration.showTime
    property bool showDate: Plasmoid.configuration.showDate
    property bool showWeekday: Plasmoid.configuration.showWeekday
    property bool showWeather: Plasmoid.configuration.showWeather
    property bool use24Hour: Plasmoid.configuration.use24Hour
    property bool showSeconds: Plasmoid.configuration.showSeconds
    property string dateFormat: Plasmoid.configuration.dateFormat
    property int fontScale: Plasmoid.configuration.fontScale
    property string panelOrder: Plasmoid.configuration.panelOrder

    readonly property real padding: Math.round(Kirigami.Units.smallSpacing / 2)
    readonly property real available: (vertical ? width : height) - padding * 2
    readonly property real fontFactor: Math.max(0.5, Math.min(2.5, fontScale / 100))

    readonly property string timeText: backend ? Util.formatTime(backend.now, use24Hour, showSeconds) : "--:--"
    readonly property string dateText: {
        if (!backend)
            return ""
        var parts = []
        if (showWeekday)
            parts.push(Util.weekday(backend.now, true))
        if (showDate)
            parts.push(Util.formatDate(backend.now, dateFormat))
        return parts.join(" ")
    }
    readonly property bool hasWeather: showWeather && backend && backend.weather !== null

    /* Sizes come from the panel thickness and the user's scale, never from the
       rendered text — deriving them from metrics would make the "do two lines
       fit" test depend on its own outcome.

       Only the clock is measured against the panel; the date and the weather
       are fixed shares of it. One scale then moves the whole strip together,
       and a panel too short for the chosen scale shrinks every part by the
       same amount instead of leaving the smaller ones behind. */
    readonly property int inlineTimeSize: Math.round(Math.max(9, Math.min(available * 0.84,
                                                                          available * 0.58 * fontFactor,
                                                                          widthLimit * Math.min(1, fontFactor))))
    readonly property int inlineDateSize: Math.round(Math.max(8, inlineTimeSize * 0.72))
    readonly property int stackedTimeSize: Math.round(Math.max(9, Math.min(available * 0.52,
                                                                           available * 0.46 * fontFactor,
                                                                           widthLimit * Math.min(1, fontFactor))))
    readonly property int stackedDateSize: Math.round(Math.max(8, stackedTimeSize * 0.68))

    /* A vertical panel limits width, not height, so the largest usable size is
       the one whose longest reading still fits across. Text width grows
       linearly with the pixel size, so a single measurement at a reference
       size answers that — measuring at the live size would tie the binding to
       its own result. */
    readonly property int refSize: 24
    readonly property real widthLimit: {
        if (!vertical)
            return Number.POSITIVE_INFINITY
        var limit = Number.POSITIVE_INFINITY
        if (showTime && timeRef.width > 0)
            limit = Math.min(limit, available * refSize / timeRef.width)
        if (dateText.length > 0 && dateRef.width > 0)
            limit = Math.min(limit, available * refSize / dateRef.width / 0.72)
        if (showWeather && tempRef.width > 0)
            limit = Math.min(limit, (available - Kirigami.Units.smallSpacing)
                                    / (1.21 + 0.78 * tempRef.width / refSize))
        return limit * 0.94
    }

    /* The weather keeps the inline proportions even when the clock is stacked:
       it is a block of its own and would look starved beside two lines. */
    readonly property int weatherTextSize: Math.round(Math.max(8, inlineDateSize * 1.08))
    readonly property int weatherGlyphSize: Math.round(Math.max(12, Math.min(available,
                                                                             weatherTextSize * 1.55)))

    /* Time and date share a stacked block only when they sit next to each
       other in the chosen order and the panel is tall enough. */
    readonly property var orderedKeys: {
        var wanted = String(panelOrder).split(",")
        var keys = []
        for (var i = 0; i < wanted.length; i++) {
            var key = wanted[i].trim()
            if (key === "time" && showTime)
                keys.push("time")
            else if (key === "date" && dateText.length > 0)
                keys.push("date")
            else if (key === "weather" && showWeather)
                keys.push("weather")
        }
        return keys
    }

    readonly property bool timeAndDateAdjacent: {
        var timeIndex = orderedKeys.indexOf("time")
        var dateIndex = orderedKeys.indexOf("date")
        return timeIndex >= 0 && dateIndex >= 0 && Math.abs(timeIndex - dateIndex) === 1
    }

    /* Vertical panels put every item on its own row already. */
    readonly property bool stacked: timeAndDateAdjacent && !vertical
                                    && available >= stackedTimeSize * 1.15 + stackedDateSize * 1.3

    readonly property int timeFontSize: stacked ? stackedTimeSize : inlineTimeSize
    readonly property int dateFontSize: stacked ? stackedDateSize : inlineDateSize

    /* The stacked block replaces the pair, so the layout iterates over this. */
    readonly property var layoutKeys: {
        if (!stacked)
            return orderedKeys
        var keys = []
        for (var i = 0; i < orderedKeys.length; i++) {
            var key = orderedKeys[i]
            if (key === "date")
                continue
            keys.push(key === "time" ? "stack" : key)
        }
        return keys
    }

    /* Widest possible readouts, so the panel never shifts as the clock ticks. */
    TextMetrics {
        id: timeMetrics
        font.pixelSize: compact.timeFontSize
        font.weight: Font.DemiBold
        text: compact.showSeconds ? (compact.use24Hour ? "00:00:00" : "00:00:00 PM")
                                  : (compact.use24Hour ? "00:00" : "00:00 PM")
    }

    TextMetrics {
        id: dateMetrics
        font.pixelSize: compact.dateFontSize
        text: {
            var sample = compact.dateFormat === "full" ? "Wednesday, 30 September"
                        : (compact.dateFormat === "iso" ? "0000-00-00" : "30 Sep")
            return compact.showWeekday ? "Wed " + sample : sample
        }
    }

    /* The same samples at a fixed size, for the vertical width budget. */
    TextMetrics {
        id: timeRef
        font.pixelSize: compact.refSize
        font.weight: Font.DemiBold
        text: timeMetrics.text
    }

    TextMetrics {
        id: dateRef
        font.pixelSize: compact.refSize
        text: dateMetrics.text
    }

    TextMetrics {
        id: tempRef
        font.pixelSize: compact.refSize
        font.weight: Font.Medium
        text: "-00°"
    }

    hoverEnabled: true
    acceptedButtons: Qt.LeftButton
    onClicked: compact.toggleRequested()

    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight

    Layout.minimumWidth: vertical ? Kirigami.Units.gridUnit : content.implicitWidth
    Layout.maximumWidth: vertical ? Number.POSITIVE_INFINITY : content.implicitWidth
    Layout.preferredWidth: vertical ? Kirigami.Units.gridUnit * 3 : content.implicitWidth
    Layout.minimumHeight: vertical ? content.implicitHeight : Kirigami.Units.gridUnit
    Layout.maximumHeight: vertical ? content.implicitHeight : Number.POSITIVE_INFINITY
    Layout.preferredHeight: vertical ? content.implicitHeight : Kirigami.Units.gridUnit * 2

    GridLayout {
        id: content

        anchors.centerIn: parent
        rows: compact.vertical ? compact.layoutKeys.length : 1
        columns: compact.vertical ? 1 : compact.layoutKeys.length
        rowSpacing: Math.round(Kirigami.Units.smallSpacing / 2)
        columnSpacing: Kirigami.Units.smallSpacing

        Repeater {
            model: compact.layoutKeys

            Loader {
                required property string modelData

                Layout.alignment: Qt.AlignCenter
                sourceComponent: {
                    switch (modelData) {
                    case "weather": return weatherItem
                    case "time": return timeItem
                    case "date": return dateItem
                    case "stack": return stackItem
                    }
                    return null
                }
            }
        }
    }

    Component {
        id: weatherItem

        RowLayout {
            spacing: Math.round(Kirigami.Units.smallSpacing / 2)

            WeatherGlyph {
                code: compact.hasWeather ? compact.backend.weather.code : 3
                day: compact.hasWeather ? compact.backend.weather.isDay : true
                opacity: compact.hasWeather ? 1 : 0.4
                implicitWidth: compact.weatherGlyphSize
                implicitHeight: implicitWidth
            }

            Text {
                text: compact.hasWeather ? Util.temperature(compact.backend.weather.temperature, "") : "--°"
                color: Kirigami.Theme.textColor
                opacity: compact.hasWeather ? 0.9 : 0.4
                font.pixelSize: compact.weatherTextSize
                font.weight: Font.Medium
            }
        }
    }

    Component {
        id: timeItem

        Text {
            text: compact.timeText
            color: Kirigami.Theme.textColor
            font.family: Kirigami.Theme.defaultFont.family
            font.pixelSize: compact.timeFontSize
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            width: Math.ceil(timeMetrics.width)
        }
    }

    Component {
        id: dateItem

        Text {
            text: compact.dateText
            color: Kirigami.Theme.textColor
            opacity: 0.65
            font.pixelSize: compact.dateFontSize
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            width: Math.ceil(dateMetrics.width)
        }
    }

    Component {
        id: stackItem

        ColumnLayout {
            spacing: 0

            Text {
                text: compact.timeText
                color: Kirigami.Theme.textColor
                font.family: Kirigami.Theme.defaultFont.family
                font.pixelSize: compact.timeFontSize
                font.weight: Font.DemiBold
                lineHeight: 0.9
                lineHeightMode: Text.ProportionalHeight
                horizontalAlignment: Text.AlignHCenter
                Layout.preferredWidth: Math.ceil(Math.max(timeMetrics.width, dateMetrics.width))
                Layout.alignment: Qt.AlignHCenter
            }

            Text {
                text: compact.dateText
                color: Kirigami.Theme.textColor
                opacity: 0.65
                font.pixelSize: compact.dateFontSize
                lineHeight: 0.9
                lineHeightMode: Text.ProportionalHeight
                horizontalAlignment: Text.AlignHCenter
                Layout.preferredWidth: Math.ceil(Math.max(timeMetrics.width, dateMetrics.width))
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }
}
