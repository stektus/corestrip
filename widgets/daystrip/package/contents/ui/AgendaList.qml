/* Events of the selected day, or the next few if that day is empty. */
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "../code/util.js" as Util

ColumnLayout {
    id: agenda

    property var backend
    property date day: new Date()
    property int revision: 0
    property int limit: 6

    readonly property var events: {
        var reactOnRevision = agenda.revision
        if (!backend)
            return []
        var sameDay = backend.eventsOn(day)
        if (sameDay.length > 0)
            return sameDay.slice(0, limit)
        return Util.sameDay(day, backend.now) ? backend.upcoming(limit) : []
    }

    spacing: Kirigami.Units.smallSpacing

    Repeater {
        model: agenda.events

        RowLayout {
            id: entry

            required property var modelData

            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Rectangle {
                implicitWidth: 3
                Layout.fillHeight: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 1.6
                radius: 1.5
                color: entry.modelData.color
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    text: entry.modelData.summary || "(no title)"
                    color: Kirigami.Theme.textColor
                    opacity: 0.9
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: {
                        var parts = []
                        if (entry.modelData.allDay)
                            parts.push("All day")
                        else
                            parts.push(Util.formatTime(entry.modelData.start, true, false)
                                       + " – " + Util.formatTime(entry.modelData.end, true, false))
                        if (entry.modelData.location)
                            parts.push(entry.modelData.location)
                        return parts.join("  ·  ")
                    }
                    color: Kirigami.Theme.textColor
                    opacity: 0.5
                    font: Kirigami.Theme.smallFont
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            Text {
                visible: !Util.sameDay(entry.modelData.start, agenda.day)
                         || !Util.sameDay(agenda.day, agenda.backend.now)
                text: agenda.backend ? Util.relativeDay(entry.modelData.start, agenda.backend.now) : ""
                color: Kirigami.Theme.textColor
                opacity: 0.4
                font: Kirigami.Theme.smallFont
            }
        }
    }

    Text {
        visible: agenda.events.length === 0
        text: {
            if (!agenda.backend || agenda.backend.calendarSources.length === 0)
                return "No calendars yet — add an iCal address in the settings"
            if (agenda.backend.calendarLoading)
                return "Loading…"
            return "Nothing scheduled"
        }
        color: Kirigami.Theme.textColor
        opacity: 0.45
        font: Kirigami.Theme.smallFont
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }
}
